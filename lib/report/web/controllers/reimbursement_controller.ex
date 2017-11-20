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
    with {:ok, csv_content} <- ReimbursementStatsCSV.get_stats(params) do
      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~S(attachment; filename="report.csv"))
      |> send_resp(200, csv_content)
    end
  end
end
