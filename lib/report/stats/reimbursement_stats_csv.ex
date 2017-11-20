defmodule Report.Stats.ReimbursementStatsCSV do
  @moduledoc false

  alias Report.Replica.MedicationRequest
  alias Report.Replica.INNMDosageIngredient
  alias Report.Repo
  import Report.Stats.ReimbursementStatsValidator, only: [validate: 1]
  import Ecto.Query

  @headers [
    pharmacy_name: "Назва суб’єкту господарювання (аптека)",
    pharmacy_edrpou: "Код ЄДРПОУ суб'єкту господарювання (аптека)",
    msp_name: "Назва закладу охорони здоров’я",
    msp_edrpou: "Код ЄДРПОУ закладу охорони здоров’я",
    doctor_name: "Лікар, що виписав рецепт (ПІБ)",
    doctor_id: "Лікар, що виписав рецепт (ID)",
    request_number: "№ Номер рецепта",
    created_at: "Дата створення рецепта",
    dispensed_at: "Дата відпуску рецепта",
    innm_name: "Міжнародна непатентована назва лікарського засобу (словник реєстру)",
    innm_dosage_name: "Лікарська форма",
    medication_name: "Торгова назва лікарського засобу",
    form: "Форма випуску (словник реєстру)",
    package_qty: "Кількість одиниць лікарської форми відповідної дози в упаковці, од.",
    medication_qty: "Кількість відпущених упаковок, упак",
    sell_amount: "Фактична роздрібна ціна реалізації упаковки, грн",
    reimbursement_amount: "Розмір відшкодування вартості лікарського засобу за упаковку, грн",
    discount_amount: "Сума відшкодування, грн",
    sell_price: "Сума доплати за упаковку ЛЗ, грн",
  ]

  def get_stats(params) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- validate(params),
         query <- get_data_query(changes),
         csv_content <- get_data(query),
         rows <- csv_content |> CSV.encode(headers: Keyword.keys(@headers)) |> Enum.to_list,
         [headers] <- [Keyword.values(@headers)] |> CSV.encode(headers: false) |> Enum.to_list
    do
      rows = case rows do
        [_h | t] -> t
        _ -> []
      end
      {:ok, [headers | rows]}
    end
  end

  defp get_data_query(%{date_from_dispense: from, date_to_dispense: to}) do
    MedicationRequest
    |> join(:left, [mr], md in assoc(mr, :medication_dispense), mr.id == md.medication_request_id)
    |> where([mr, md], fragment("? BETWEEN ? AND ?", md.dispensed_at, ^from, ^to))
    |> join(:left, [mr, md], m_req in assoc(mr, :medication))
    |> join(:left, [mr, md], e_req in assoc(mr, :employee))
    |> join(:left, [mr, md, m_req, e_req], p_req in assoc(e_req, :party))
    |> join(:left, [mr, md], le_req in assoc(mr, :legal_entity))
    |> join(:left, [mr, md], le_dis in assoc(md, :legal_entity))
    |> join(:left, [mr, md], ing in INNMDosageIngredient, ing.parent_id == mr.medication_id and ing.is_primary)
    |> join(:left, [..., ing], innm in assoc(ing, :innm))
    |> join(:left, [mr, md], d in assoc(md, :details))
    |> join(:left, [..., d], m_det in assoc(d, :medication))
  end

  defp get_data(query) do
      query
      |> select(
        [mr, md, m_req, e_req, p_req, le_req, le_dis, _ing, innm, d, m_det],
        %{
          medication_request: %{mr | medication: m_req},
          medication_dispense: md,
          legal_entity_dis: le_dis,
          legal_entity_req: le_req,
          employee: e_req,
          party: p_req,
          innm: innm,
          details: d,
          medication_details: m_det
        }
      )
      |> Repo.all
      |> Enum.map(fn item ->
        medication_request = item.medication_request
        medication_dispense = item.medication_dispense
        dispense_legal_entity = item.legal_entity_dis || %{}
        legal_entity = item.legal_entity_req || %{}
        employee = item.employee || %{}
        party = item.party || %{}
        innm = item.innm || %{}
        details = item.details || %{}
        medication_details = item.medication_details || %{}
        %{
          msp_name: Map.get(legal_entity, :name),
          msp_edrpou: Map.get(legal_entity, :edrpou),
          doctor_name: "#{Map.get(party, :last_name)} #{Map.get(party, :first_name)} #{Map.get(party, :second_name)}",
          doctor_id: Map.get(employee, :id),
          request_number: medication_request.request_number,
          created_at: to_string(medication_request.created_at),
          innm_dosage_name: medication_request.medication.name,
          pharmacy_name: Map.get(dispense_legal_entity, :name),
          pharmacy_edrpou: Map.get(dispense_legal_entity, :edrpou),
          dispensed_at: to_string(Map.get(medication_dispense, :dispensed_at)),
          innm_name: Map.get(innm, :name),
          medication_name: Map.get(medication_details, :name),
          form: Map.get(medication_details, :form),
          package_qty: Map.get(medication_details, :package_qty),
          medication_qty: Map.get(details, :medication_qty),
          sell_amount: Map.get(details, :sell_amount),
          reimbursement_amount: Map.get(details, :reimbursement_amount),
          discount_amount: Map.get(details, :discount_amount),
          sell_price: Map.get(details, :sell_price),
        }
      end)
  end
end
