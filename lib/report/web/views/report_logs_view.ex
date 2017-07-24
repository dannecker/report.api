defmodule Report.Web.ReportLogsView do
  @moduledoc false

  use Report.Web, :view

  def render("index.json", %{"report_logs": report_logs}) do
    render_many(report_logs, Report.Web.ReportLogsView, "show.json")
  end

  def render("show.json", %{"report_logs": report_logs}) do
    %{
       id: report_logs.id,
       inserted_at: report_logs.inserted_at,
       public_url: report_logs.public_url,
       type: report_logs.type
     }
  end
  def render("index.json", %{"status": status}) do
    %{status: status}
  end
end
