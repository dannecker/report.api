defmodule Report.Web.ReimbursementView do
  @moduledoc false

  use Report.Web, :view

  def render("index.json", %{stats: stats}) do
    render_many(stats, __MODULE__, "reimbursement.json")
  end

  def render("reimbursement.json", %{reimbursement: reimbursement}) do
    employee = reimbursement.employee
    legal_entity = employee.legal_entity
    division = reimbursement.division
    medication = reimbursement.medication
    medical_program = reimbursement.medical_program

    medication_request =
      reimbursement
      |> Map.take(~w(
        id
        created_at
        started_at
        ended_at
        status
        dispense_valid_from
        dispense_valid_to
        person_id
        medication_qty
        rejected_at
        rejected_by
        rejected_reason
      )a)
      |> Map.merge(%{
        "legal_entity" => render_one(legal_entity, __MODULE__, "legal_entity.json", as: :legal_entity),
        "division" => render_one(division, __MODULE__, "division.json", as: :division),
        "employee" => render_one(employee, __MODULE__, "employee.json", as: :employee),
        "medication" => render_one(medication, __MODULE__, "medication.json", as: :medication),
        "medical_program" => render_one(medical_program, __MODULE__, "medical_program.json", as: :medical_program)
      })

      medication_dispense = reimbursement.medication_dispense || %{}
      party = Map.get(medication_dispense, :party, %{})
      division = Map.get(medication_dispense, :division, %{})
      legal_entity = Map.get(medication_dispense, :legal_entity, %{})
      medical_program = Map.get(medication_dispense, :medical_program, %{})
      details = Map.get(medication_dispense, :details, [])
      medication_dispense =
        medication_dispense
        |> Map.take(~w(id dispensed_at status)a)
        |> Map.merge(%{
          "party" => render_one(party, __MODULE__, "party.json", as: :party),
          "division" => render_one(division, __MODULE__, "division.json", as: :division),
          "legal_entity" => render_one(legal_entity, __MODULE__, "legal_entity.json", as: :legal_entity),
          "medical_program" => render_one(medical_program, __MODULE__, "medical_program.json", as: :medical_program),
          "medications" => render_many(details, __MODULE__, "medication_dispense_details.json", as: :details)
        })

      %{
        "medication_request" => medication_request,
        "medication_dispense" => medication_dispense,
      }
  end

  def render("legal_entity.json", %{legal_entity: legal_entity}) do
    Map.take(legal_entity, ~w(id name edrpou)a)
  end

  def render("employee.json", %{employee: employee}) do
    party = employee.party
    employee
    |> Map.take(~w(id party_id position employee_type)a)
    |> Map.merge(Map.take(party, ~w(first_name last_name second_name)a))
  end

  def render("division.json", %{division: division}) do
    division
    |> Map.take(~w(id name mountain_group)a)
    |> Map.merge(%{"address" => Enum.find(division.addresses, &(Map.get(&1, "type") == "RESIDENCE"))})
  end

  def render("medication.json", %{medication: medication}) do
    Map.take(medication, ~w(id name form)a)
  end

  def render("medical_program.json", %{medical_program: medical_program}) do
    Map.take(medical_program, ~w(id name)a)
  end

  def render("party.json", %{party: party}) do
    Map.take(party, ~w(id first_name last_name second_name)a)
  end

  def render("medication_dispense_details.json", %{details: details}) do
    medication = Map.get(details, :medication, %{})

    medication
    |> Map.take(~w(id code_atc name type manufacturer form container package_qty)a)
    |> Map.put(:dispense_details, Map.take(details, ~w(
      medication_qty
      sell_price
      sell_amount
      discount_amount
      reimbursement_amount
    )a))
  end
end
