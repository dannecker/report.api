defmodule Report.Stats.ReimbursementStatsValidator do
  @moduledoc false

  import Ecto.Changeset
  import Ecto.Query
  alias Report.Repo
  alias Report.Stats.ReimbursementRequest
  alias Report.Stats.ReimbursementCSVRequest
  alias Report.Replica.PartyUser
  alias Report.Replica.Party
  alias Report.Replica.Employee
  alias Report.Replica.LegalEntity
  alias Report.Stats.ReimbursementRequest.EmbeddedData
  alias Report.Stats.ReimbursementRequest.Period

  def validate(_, nil, _) do
    {:error, [{%{
      description: "Legal entity not found",
      params: [],
      rule: :invalid
    }, "$.legal_entity_id"}]}
  end
  def validate(_, _, nil) do
    {:error, [{%{
      description: "Party not found",
      params: [],
      rule: :invalid
    }, "$.party_id"}]}
  end
  def validate(params, legal_entity_id, user_id) do
    with %LegalEntity{} = legal_entity <- get_legal_entity(legal_entity_id),
         :ok <- validate_legal_entity_type(legal_entity),
         :ok <- validate_active_legal_entity(legal_entity),
         %PartyUser{party: party} <- get_party_user(user_id),
         :ok <- validate_active_party(party, legal_entity_id)
    do
      {changeset(%ReimbursementRequest{}, params), legal_entity}
    end
  end
  def validate(params) do
    changeset(%ReimbursementCSVRequest{}, params)
  end

  def changeset(%ReimbursementCSVRequest{} = reimbursement_csv_request, params) do
    fields = ~w(date_from_dispense date_to_dispense)a
    changeset =
      reimbursement_csv_request
      |> cast(params, fields)
      |> validate_required(fields)

    with :ok <- do_validate_period(changeset, :date_from_dispense, :date_to_dispense) do
      changeset
    else
      :error ->
        add_error(changeset, :date_from_dispense, "Input dates are not valid")
    end
  end
  def changeset(%ReimbursementRequest{} = reimbursement_request, params) do
    dispense = Period.changeset(%Period{}, %{
      "from" => Map.get(params, "date_from_dispense"),
      "to" => Map.get(params, "date_to_dispense")
    })
    request = Period.changeset(%Period{}, %{
      "from" => Map.get(params, "date_from_request"),
      "to" => Map.get(params, "date_to_request")
    })
    period =
      %EmbeddedData{}
      |> EmbeddedData.changeset()
      |> put_embed(:dispense, dispense)
      |> put_embed(:request, request)

    reimbursement_request
    |> change()
    |> put_embed(:period, period)
    |> validate_dates()
  end

  defp validate_dates(%Ecto.Changeset{} = changeset) do
    %Ecto.Changeset{changes: dispense_changes} =
      changeset
      |> get_change(:period)
      |> get_change(:dispense)
    %Ecto.Changeset{changes: request_changes} =
      changeset
      |> get_change(:period)
      |> get_change(:request)
    with true <- dispense_changes != %{} || request_changes != %{},
         %Ecto.Changeset{valid?: true} = changeset <- validate_period(changeset, :dispense),
         %Ecto.Changeset{valid?: true} = changeset <- validate_period(changeset, :request)
    do
      changeset
    else
      false -> add_error(changeset, :period, "At least one of input dates must be not empty")
      changeset -> changeset
    end
  end

  defp validate_period(changeset, field) do
    period_changeset = get_change(changeset, :period)
    field_changeset = get_change(period_changeset, field)

    with :ok <- do_validate_period(field_changeset) do
      changeset
    else
      :error ->
        period_changeset = add_error(period_changeset, field, "Input dates are not valid")
        put_embed(changeset, :period, period_changeset)
    end
  end

  defp do_validate_period(%Ecto.Changeset{changes: changes}, _, _) when changes == %{}, do: :ok
  defp do_validate_period(field_changeset, field_from \\ :from, field_to \\ :to) do
    from = get_change(field_changeset, field_from)
    to = get_change(field_changeset, field_to)
    with true <- !is_nil(from) && !is_nil(to),
         true <- Date.compare(from, to) != :gt
    do
      :ok
    else
      _ -> :error
    end
  end

  defp get_legal_entity(id) do
    Repo.get(LegalEntity, id)
  end

  defp get_party_user(user_id) do
    PartyUser
    |> where([pu], pu.user_id == ^user_id)
    |> preload(:party)
    |> Repo.one()
  end

  defp validate_legal_entity_type(%LegalEntity{type: type}) when type in ["MSP", "PHARMACY"], do: :ok
  defp validate_legal_entity_type(_) do
    {:error, :forbidden}
  end

  defp validate_active_legal_entity(%LegalEntity{is_active: true, status: "ACTIVE"}), do: :ok
  defp validate_active_legal_entity(_), do: {:error, :forbidden}

  defp validate_active_party(%Party{id: id}, legal_entity_id) do
    employees =
      Employee
      |> where([e], party_id: ^id)
      |> Repo.all
    Enum.reduce_while(employees, {:error, :forbidden}, fn employee, acc ->
      if is_active_employee(employee) && employee.legal_entity_id == legal_entity_id do
        {:halt, :ok}
      else
        {:cont, acc}
      end
    end)
  end

  defp is_active_employee(employee) do
    employee.is_active && employee.status == "APPROVED"
  end
end
