defmodule Report.Billings do
  @moduledoc false
  require Logger
  import Ecto.Query
  import Ecto.Changeset
  alias Report.Billing
  alias Report.Repo
  alias Report.Replica.Replicas
  alias Report.Replica.Declaration
  alias Report.Replica.LegalEntity
  alias Report.GandalfCaller
  alias Report.RedLists
  alias Report.MediaStorage

  @maturity_age Confex.get_env(:report_api, :maturity_age)
  @declarations_bucket Confex.fetch_env!(:report_api, Report.MediaStorage)[:declarations_bucket]

  def get_last_billing_date do
    Billing
    |> select([:billing_date])
    |> order_by([desc: :billing_date])
    |> first
    |> Repo.one
    |> get_billing_date
  end
  defp get_billing_date(nil), do: Replicas.get_oldest_declaration_date()
  defp get_billing_date(billing) when is_map(billing), do: Map.get(billing, :billing_date)

  def create_billing(%Declaration{person: person, division: division} = declaration) do
    with billing_chset <- billing_changeset(%Billing{}, declaration, person, division),
         {:ok, billing} <- Repo.insert(billing_chset)
    do
      Logger.info fn -> "Billing was created for #{billing.declaration.id}" end
      billing
    else
      {:error, error_chset} ->
        Logger.error fn -> """
          #{error_chset.errors} for
          declaration_id=#error_chsetchanges.declaration.data.id}
          legal_entity_id=#error_chsetchanges.legal_entity.data.id}
          """
        end
    end
  end

  def billing_changeset(billing, declaration, person, division) do
    billing
    |> cast(%{}, [])
    |> put_assoc(:legal_entity, declaration.legal_entity)
    |> put_assoc(:declaration, declaration)
    |> put_assoc(:division, division)
    |> put_change(:billing_date, Timex.today)
    |> put_mountain_group(division)
    |> put_person_age(person)
    |> put_decision()
    |> put_red_msp(person)
    |> put_is_valid(declaration, validate_signed_content())
  end

  defp put_mountain_group(billing_chset, division) do
    put_change(billing_chset, :mountain_group, division.mountain_group)
  end

  defp put_decision(billing_chset) do
    make_decision(billing_chset)
  end

  defp put_red_msp(billing_chset, person) do
    red_msp_id =
      if RedLists.person_already_found_in_red_lists?(person.id) do
        %{"settlement_id" => settlement_id, "street" => street_name, "building" => building} =
        person.addresses
        |> Enum.filter(fn a -> a["type"] == "REGISTRATION" end)
        |> List.first
        find_msp_territory(billing_chset, settlement_id, street_name, building)
      else
        nil
      end
    put_change(billing_chset, :red_msp_id, red_msp_id)
  end

  def put_is_valid(changeset, %{id: id} = declaration, true) do
    with {:ok, %{"data" => %{"secret_url" => url}}} <- get_signed_declaration_url(id),
         {:ok, %{"data" => %{"is_valid" => is_valid}}} <- validate_declaration(declaration, url)
    do
      put_change(changeset, :is_valid, is_valid)
    else
      _ -> put_change(changeset, :is_valid, false)
    end
  end
  def put_is_valid(changeset, _, false), do: changeset

  defp find_msp_territory(billing_chset, settlement_id, street_name, building) do
    red_list = RedLists.find_msp_territory(settlement_id, street_name, building)
    case length(red_list) do
      0 ->
        maybe_one_division_in_settlement(settlement_id)
      1 ->
        red_list
        |> List.first()
        |> Map.get(:red_msp_id)
      list_length when list_length > 1 ->
        maybe_child(billing_chset, red_list)
    end
  end

  defp maybe_one_division_in_settlement(settlement_id) do
    red_list = RedLists.find_msp_territory(settlement_id)
    case length(red_list) do
      0 ->
        nil
      1 ->
        red_list
        |> List.first()
        |> Map.get(:red_msp_id)
      list_length when list_length > 1 ->
        red_list
        |> Enum.find(nil, fn mspt -> mspt.street_name == nil end)
        |> Map.get(:red_msp_id)
    end
  end

  defp maybe_child(%Ecto.Changeset{changes: changes}, red_list) do
    if changes.person_age < @maturity_age do
      RedLists.find_msp_by_type(red_list, "child")
    else
      RedLists.find_msp_by_type(red_list, "general")
    end
  end

  defp make_decision(billing_chset) do
    person_age = billing_chset.changes.person_age
    mountain_group = billing_chset.changes.mountain_group
    decision_params = GandalfCaller.make_decision(%{"mountain_group": mountain_group, "age": person_age})
    billing_chset
    |> put_change(:decision_id, decision_params.id)
    |> put_change(:compensation_group, decision_params.decision)
  end

  defp put_person_age(billing_chset, person) do
    person_age = Timex.diff(Timex.today, person.birth_date, :years)
    put_change(billing_chset, :person_age, person_age)
  end

  defp validate_signed_content do
    Confex.get_env(:report_api, :validate_signed_content, false)
  end

  def list_billing(query \\ Billing) do
    Repo.all(query)
  end

  def todays_billing(query) do
    where(query, [q], q.billing_date == ^Timex.today)
  end

  def get_billing_for_capitation(date \\ Timex.today) do
    date
    |> get_legal_entities_for_csv()
    |> Repo.stream(timeout: :infinity)
  end

  def count_billing_by_red_edrpou(edrpou) do
    from b in Billing,
    join: msp in RedMSP, on: b.red_msp_id == msp.id,
    where: msp.edrpou == ^edrpou,
    group_by: msp.id
  end

  def get_legal_entities_for_csv(billing_date) do
    from le in LegalEntity,
    full_join: b in Billing, on: le.id == b.legal_entity_id,
    where: b.billing_date == ^billing_date,
    or_where: is_nil(b.billing_date),
    group_by: [le.edrpou, b.mountain_group, le.name],
    order_by: le.edrpou,
    select: [
      le.edrpou,
      le.name,
      b.mountain_group,
      fragment(~s(sum\(case when person_age<5 then 1 else 0 end\) as "0-5")),
      fragment(~s(sum\(case when person_age>=5 and person_age<18 then 1 else 0 end\) as "6-17")),
      fragment(~s(sum\(case when person_age>17 and person_age<40 then 1 else 0 end\) as "18-39")),
      fragment(~s(sum\(case when person_age>39 and person_age<65 then 1 else 0 end\) as "40-64")),
      fragment(~s(sum\(case when person_age>64 then 1 else 0 end\) as ">65"))
    ]
  end

  defp get_signed_declaration_url(id) do
    MediaStorage.create_signed_url("GET", @declarations_bucket, "signed_content", id)
  end

  defp validate_declaration(declaration, url) do
    MediaStorage.validate_signed_entity(%{
      "url" => url,
      "rules" => [
        %{
          "field" => ["legal_entity", "edrpou"],
          "type" => "eq",
          "value" => declaration.legal_entity.edrpou,
        },
      ]
    })
  end
end
