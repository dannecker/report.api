defmodule Report.Web.ReimbursementController do
  @moduledoc false

  use Report.Web, :controller

  alias Report.Stats.ReimbursementStats
  alias Report.Stats.ReimbursementStatsCSV
  alias Scrivener.Page

  action_fallback Report.Web.FallbackController

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with %Page{} = paging <- ReimbursementStats.get_stats(params, headers) do
      render(conn, "index.json", stats: paging.entries, paging: paging)
    end
  end

  def download(conn, params) do
    headers = [
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
    with {:ok, csv_content} <- ReimbursementStatsCSV.get_stats(params),
         [_ | data] <- csv_content |> CSV.encode(headers: Keyword.keys(headers)) |> Enum.to_list,
         [headers] <- [Keyword.values(headers)] |> CSV.encode(headers: false) |> Enum.to_list,
         data <- [headers | data]
    do
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~S(attachment; filename="report.csv"))
      |> send_resp(200, data)
    end
  end
end
