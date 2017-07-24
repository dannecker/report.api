defmodule Report.Web.ReportLogsController do
  @moduledoc false

  use Report.Web, :controller

  alias Report.ReportLogs
  alias Report.Repo
  alias Report.Reporter

  action_fallback Report.Web.FallbackController

  def index(conn, _params) do
    with report_logs <- ReportLogs.list_report_logs() do
      render(conn, "index.json", report_logs: report_logs)
    end
  end

  def temp_capitation(conn, _params) do
    Repo.delete_all(Report.Billing)
    Reporter.capitation
    render(conn, "index.json", status: "ok")
  end
end
