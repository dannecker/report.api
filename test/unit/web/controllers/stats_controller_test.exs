defmodule Report.Web.StatsControllerTest do
  @moduledoc false
  use Report.Web.ConnCase

  test "get main stats with invalid params", %{conn: conn} do
    conn = get conn, "/reports/stats"
    assert response(conn, 422)

    conn = get conn, "/reports/stats", from_date: "2017-01-01"
    assert response(conn, 422)

    conn = get conn, "/reports/stats", to_date: "2017-01-01"
    assert response(conn, 422)

    conn = get conn, "/reports/stats", from_date: "2017-01", to_date: "2017-02"
    assert response(conn, 422)

    conn = get conn, "/reports/stats", from_date: "2017-07-01", to_date: "2017-01-01"
    assert response(conn, 422)

    conn = get conn, "/reports/stats", from_date: "2017-01-01", to_date: "2017-07-01"
    assert response(conn, 200)

    now = Date.utc_today()
    conn = get conn, "/reports/stats", from_date: "2017-01-01", to_date: to_string(now)
    schema =
      "test/data/stats/main_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))
  end
end
