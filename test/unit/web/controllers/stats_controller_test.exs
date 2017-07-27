defmodule Report.Web.StatsControllerTest do
  @moduledoc false

  use Report.Web.ConnCase
  import Report.Web.Router.Helpers
  alias Report.Stats.HistogramStatsRequest

  test "get main stats", %{conn: conn} do
    conn = get conn, stats_path(conn, :index)
    schema =
      "test/data/stats/main_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))
  end

  test "get division stats", %{conn: conn} do
    assert_raise(Ecto.NoResultsError, fn ->
      get conn, stats_path(conn, :division, Ecto.UUID.generate())
    end)

    division = insert(:division)
    conn = get conn, stats_path(conn, :division, division.id)
    schema =
      "test/data/stats/division_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))
  end

  test "get regions stats", %{conn: conn} do
    assert_raise(Ecto.NoResultsError, fn ->
      get conn, stats_path(conn, :region, Ecto.UUID.generate())
    end)

    region = insert(:region)
    conn = get conn, stats_path(conn, :region, region.id)
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

    conn = get conn, stats_path(conn, :histogram,
      from_date: "2017-01",
      to_date: "2017-02",
      interval: HistogramStatsRequest.interval(:day)
    )
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram,
      from_date: "2017",
      to_date: "2017",
      interval: HistogramStatsRequest.interval(:month)
    )
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram,
      from_date: "2017-07-01",
      to_date: "2017-01-01",
      interval: HistogramStatsRequest.interval(:month)
    )
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram,
      from_date: "2017-07-01",
      to_date: "2017-01-01",
      interval: HistogramStatsRequest.interval(:day)
    )
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram,
      from_date: "2017",
      to_date: "2015",
      interval: HistogramStatsRequest.interval(:year)
    )
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :histogram,
      from_date: "2017-01-01",
      to_date: "2017-07-01",
      interval: HistogramStatsRequest.interval(:day)
    )
    assert response(conn, 200)

    conn = get conn, stats_path(conn, :histogram,
      from_date: Timex.now() |> Timex.shift(days: -5) |> Timex.format!("%F", :strftime),
      to_date: to_string(Date.utc_today()),
      interval: HistogramStatsRequest.interval(:day)
    )
    schema =
      "test/data/stats/histogram_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))
  end
end
