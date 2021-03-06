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
    schema =
      "test/data/stats/regions_stats_response.json"
      |> File.read!()
      |> Poison.decode!()

    conn = get conn, stats_path(conn, :regions)
    :ok = NExJsonSchema.Validator.validate(schema, json_response(conn, 200))

    insert(:region)
    conn = get conn, stats_path(conn, :regions)
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

  test "get divisions map stats", %{conn: conn} do
    conn = get conn, stats_path(conn, :divisions_map)
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :divisions_map,
      lefttop_latitude: "50.32423",
      lefttop_longitude: "30.1233",
      rightbottom_latitude: "50.32423",
    )
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :divisions_map,
      lefttop_latitude: "invalid",
      lefttop_longitude: "50.32423",
      rightbottom_latitude: "50.32423",
      rightbottom_longitude: "50.32423"
    )
    assert response(conn, 422)

    conn = get conn, stats_path(conn, :divisions_map,
      lefttop_latitude: "50.32423",
      lefttop_longitude: "30.1233",
      rightbottom_latitude: "50.32423",
      rightbottom_longitude: "50.32423"
    )
    assert response(conn, 200)

    conn = get conn, stats_path(conn, :divisions_map,
      type: "invalid",
      lefttop_latitude: "50.32423",
      lefttop_longitude: "30.1233",
      rightbottom_latitude: "50.32423",
      rightbottom_longitude: "50.32423"
    )
    assert response(conn, 422)

    insert_fixtures()
    conn = get conn, stats_path(conn, :divisions_map,
      lefttop_latitude: 45,
      lefttop_longitude: 35,
      rightbottom_latitude: 55,
      rightbottom_longitude: 25,
      page_size: 3,
    )
    assert map_stats = response(conn, 200)
    map_stats = Poison.decode!(map_stats)

    schema =
      "test/data/stats/divisions_map_response.json"
      |> File.read!()
      |> Poison.decode!()

    :ok = NExJsonSchema.Validator.validate(schema, map_stats)

    assert 3 == Enum.count(map_stats["data"])
    assert is_map(map_stats["paging"])
    assert 2 == map_stats["paging"]["total_pages"]
    assert 3 == map_stats["paging"]["page_size"]
    assert 4 == map_stats["paging"]["total_entries"]
  end

  defp insert_fixtures do
    insert(:division, location: %Geo.Point{coordinates: {30.1233, 50.32423}})
    insert(:division, location: %Geo.Point{coordinates: {30.1233, 50.32423}})
    insert(:division, location: %Geo.Point{coordinates: {30.1233, 50.32423}})
    insert(:division, location: %Geo.Point{coordinates: {30.1233, 50.32423}})
  end
end
