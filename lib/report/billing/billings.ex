defmodule Report.Billings do
  @moduledoc false
  require Logger
  import Ecto.Query
  import Ecto.Changeset
  alias Report.Billing
  alias Report.Repo
  alias Report.Replica.Replicas
  alias Report.Replica.Declaration
  alias Ecto.Adapters.SQL

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
  end

  defp put_mountain_group(billing_chset, division) do
    put_change(billing_chset, :mountain_group, division.mountain_group)
  end

  defp put_person_age(billing_chset, person) do
    person_age = Timex.diff(Timex.today, person.birth_date, :years)
    put_change(billing_chset, :person_age, person_age)
  end

  def list_billing(query \\ Billing) do
    Repo.all(query)
  end

  def todays_billing(query) do
    where(query, [q], q.billing_date == ^Timex.today)
  end

  def get_billing_for_capitation(date \\ Timex.today) do
    raw_sql_to_map(aggregate_for_capitation_sql())
  end

  defp raw_sql_to_map(sql) do
    res = SQL.query!(Repo, sql, [Timex.today])
    cols = Enum.map(res.columns, &(String.to_atom(&1)))
    Enum.map(res.rows, &Enum.zip(cols, &1))
  end

  defp aggregate_for_capitation_sql do
    """
      select le.edrpou, le.name, b.mountain_group,
      sum(case when person_age<5 then 1 else 0 end) as "0-5",
      sum(case when person_age>=5 and person_age<18 then 1 else 0 end) as "6-17",
      sum(case when person_age>17 and person_age<40 then 1 else 0 end) as "18-39",
      sum(case when person_age>39 and person_age<65 then 1 else 0 end) as "40-64",
      sum(case when person_age>64 then 1 else 0 end) as ">65"
      from billings as b
      join legal_entities le on (b.legal_entity_id = le.id)
      where b.billing_date = $1::date
      group by b.legal_entity_id, b.mountain_group, le.name, le.edrpou
      order by le.edrpou
    """
  end
end
