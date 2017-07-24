defmodule Report.Web.StatsControllerTest do
  @moduledoc false
  use Report.Web.ConnCase
  import Report.Web.Router.Helpers

  test "get main stats", %{conn: conn} do
    conn = get conn, stats_path(conn, :index)
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :index, from_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :index, to_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :index, from_date: "2017-01", to_date: "2017-02")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :index, from_date: "2017-07-01", to_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :index, from_date: "2017-01-01", to_date: "2017-07-01")
    assert response(conn, 200)

    now = Date.utc_today()
    conn = get conn, stats_path(conn, :index, from_date: "2017-01-01", to_date: to_string(now))
    schema =
      "test/data/stats/main_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))
  end

  test "get division stats", %{conn: conn} do
    schema =
      "test/data/stats/division_stats_response.json"
      |> File.read!()
      |> Poison.decode!()

    conn = get conn, stats_path(conn, :divisions, Ecto.UUID.generate())
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))
  end

  test "get regions stats", %{conn: conn} do
    conn = get conn, stats_path(conn, :regions)
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :regions, from_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :regions, to_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :regions, from_date: "2017-01", to_date: "2017-02")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :regions, from_date: "2017-07-01", to_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :regions, from_date: "2017-01-01", to_date: "2017-07-01")
    assert response(conn, 200)

    conn = get conn, stats_path(conn, :regions,
      from_date: "2017-01-01",
      to_date: "2017-07-01",
      region_id: Ecto.UUID.generate()
    )
    assert response(conn, 404)

    region = insert(:region)

    conn = get conn, stats_path(conn, :regions,
      from_date: "2017-01-01",
      to_date: "2017-07-01",
      region_id: region.id
    )
    schema =
      "test/data/stats/regions_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))
  end

  test "get histogram stats", %{conn: conn} do
    conn = get conn, stats_path(conn, :histogram)
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram, from_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram, to_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram, from_date: "2017-01", to_date: "2017-02")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram, from_date: "2017-07-01", to_date: "2017-01-01")
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram, from_date: "2017-01-01", to_date: "2017-07-01")
    assert response(conn, 200)

    conn = get conn, stats_path(conn, :histogram,
      from_date: "2017-01-01",
      to_date: "2017-07-01",
      region_id: Ecto.UUID.generate()
    )
    assert response(conn, 404)

    region = insert(:region)

    conn = get conn, stats_path(conn, :histogram,
      from_date: Timex.now() |> Timex.shift(days: -5) |> Timex.format!("%F", :strftime),
      to_date: to_string(Date.utc_today()),
      region_id: region.id
    )
    schema =
      "test/data/stats/histogram_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))
  end
end
