defmodule Report.Web.ReportLogsControllerTest do
  @moduledoc false
  use Report.Web.ConnCase
  import Report.Factory

  test "report log index", %{conn: conn}  do
    insert_list(3, :report_log)
    conn = get conn, report_logs_path(conn, :index)
    assert response(conn, 200)
  end

  test "report log temp url", %{conn: conn} do
    conn = get conn, report_logs_path(conn, :temp_capitation)
    assert response(conn, 200)
  end
end
