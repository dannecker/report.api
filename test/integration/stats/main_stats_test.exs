defmodule Report.Integration.MainStatsTest do
  use Report.Web.ConnCase

  alias Report.Stats.HistogramStatsRequest
  alias Report.Stats.MainStats
  use Timex

  test "get_main_stats/1" do
    insert_fixtures()
    from_date = "2017-01-01"
    to_date = to_string(Date.utc_today())

    {:ok, main_stats} = MainStats.get_main_stats(%{"from_date" => from_date, "to_date" => to_date})
    schema =
      "test/data/stats/main_stats_response.json"
      |> File.read!()
      |> Poison.decode!()

    schema = Map.put(schema, "properties", get_in(schema, ~w(properties data properties)))
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert %{"from_date" => ^from_date, "to_date" => ^to_date} = main_stats
    assert %{"declarations_closed" => 1,
             "declarations_created" => 1,
             "declarations_total" => 2,
             "doctors" => 2,
             "msps" => 3} = main_stats["period"]
    assert %{"declarations_closed" => 1,
             "declarations_created" => 1,
             "declarations_total" => 2,
             "doctors" => 2,
             "msps" => 3} = main_stats["total"]
  end

  test "get_division_stats/1" do
    %{"division" => division} = insert_fixtures()

    {:ok, main_stats} = MainStats.get_division_stats(division.id)
    schema =
      "test/data/stats/division_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)
    assert %{"declarations_closed" => 1,
             "declarations_created" => 1,
             "declarations_total" => 2,
             "doctors" => 1} = main_stats["total"]
  end

  test "get_regions_stats/1" do
    %{"region" => region} = insert_fixtures()
    from_date = "2017-01-01"
    to_date = to_string(Date.utc_today())

    {:ok, main_stats} = MainStats.get_regions_stats(%{
      "from_date" => from_date,
      "to_date" => to_date
    })
    schema =
      "test/data/stats/regions_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert %{"from_date" => ^from_date, "to_date" => ^to_date} = main_stats
    assert 2 = Enum.count(main_stats["regions"])

    {:ok, main_stats} = MainStats.get_regions_stats(%{
      "from_date" => from_date,
      "to_date" => to_date,
      "region_id" => region.id
    })
    schema =
      "test/data/stats/regions_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert 1 = Enum.count(main_stats["regions"])
    region_stats = hd(main_stats["regions"])
    assert %{"region" => %{"name" => "ЛЬВІВСЬКА"}} = region_stats
    assert %{"declarations_closed" => 1,
             "declarations_created" => 1,
             "declarations_total" => 2,
             "doctors" => 2,
             "msps" => 1} = region_stats["period"]
    assert %{"declarations_closed" => 1,
             "declarations_created" => 1,
             "declarations_total" => 2,
             "doctors" => 2,
             "msps" => 1} = region_stats["total"]
  end

  test "get_histogram_stats/1" do
    %{"region" => region} = insert_fixtures()
    now = Timex.now
    from_date =
      now
      |> Timex.shift(days: -20)
      |> Timex.format!("%F", :strftime)
    to_date = to_string(Date.utc_today())

    {:ok, main_stats} = MainStats.get_histogram_stats(%{
      "from_date" => from_date,
      "to_date" => to_date,
    })
    schema =
      "test/data/stats/histogram_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    schema =
      schema
      |> Map.put("type", "array")
      |> Map.put("items", schema["properties"]["data"]["items"])
      |> Map.delete("properties")
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert 21 = Enum.count(main_stats)
    assert %{
      "interval" => %{
      "from_date" => ^from_date,
      "to_date" => ^from_date
    }} = List.first(main_stats)

    assert %{
      "interval" => %{
      "from_date" => ^to_date,
      "to_date" => ^to_date
    }} = List.last(main_stats)
    assert %{
      "msps" => 1,
      "doctors" => 2,
      "declarations_total" => 2,
      "declarations_created" => 1,
      "declarations_closed" => 1} = main_stats |> List.last |> Map.get("period")
    assert %{
      "msps" => 1,
      "doctors" => 2,
      "declarations_total" => 2,
      "declarations_created" => 1,
      "declarations_closed" => 1} = main_stats |> List.last |> Map.get("total")

    from_date =
      now
      |> Timex.beginning_of_month()
      |> Timex.format!("%F", :strftime)
    to_date =
      now
      |> Timex.end_of_month()
      |> Timex.format!("%F", :strftime)
    {:ok, main_stats} = MainStats.get_histogram_stats(%{
      "from_date" => from_date,
      "to_date" => to_date,
      "region_id" => region.id,
      "interval" => HistogramStatsRequest.interval(:month)
    })
    schema =
      "test/data/stats/histogram_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    schema =
      schema
      |> Map.put("type", "array")
      |> Map.put("items", schema["properties"]["data"]["items"])
      |> Map.delete("properties")
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert 1 = Enum.count(main_stats)
    assert %{
      "interval" => %{
      "from_date" => ^from_date,
      "to_date" => ^to_date
    }} = List.first(main_stats)

    from_date =
      now
      |> Timex.beginning_of_year()
      |> Timex.format!("%F", :strftime)
    to_date =
      now
      |> Timex.end_of_year()
      |> Timex.format!("%F", :strftime)
    {:ok, main_stats} = MainStats.get_histogram_stats(%{
      "from_date" => from_date,
      "to_date" => to_date,
      "region_id" => region.id,
      "interval" => HistogramStatsRequest.interval(:year)
    })
    schema =
      "test/data/stats/histogram_stats_response.json"
      |> File.read!()
      |> Poison.decode!()
    schema =
      schema
      |> Map.put("type", "array")
      |> Map.put("items", schema["properties"]["data"]["items"])
      |> Map.delete("properties")
    :ok = NExJsonSchema.Validator.validate(schema, main_stats)

    assert 1 = Enum.count(main_stats)
    assert %{
      "interval" => %{
      "from_date" => ^from_date,
      "to_date" => ^to_date
    }} = List.first(main_stats)
  end

  test "histogram_intervals/1" do
    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-01-10],
      interval: HistogramStatsRequest.interval(:day)
    }
    assert 10 == Enum.count(MainStats.histogram_intervals(request))

    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-05-10],
      interval: HistogramStatsRequest.interval(:month)
    }
    assert 5 == Enum.count(MainStats.histogram_intervals(request))

    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-05-10],
      interval: HistogramStatsRequest.interval(:year)
    }
    assert 1 == Enum.count(MainStats.histogram_intervals(request))
  end

  test "histogram_stats_skeleton/2" do
    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-01-10],
      interval: HistogramStatsRequest.interval(:day)
    }
    skeleton =
      request
      |> MainStats.histogram_intervals()
      |> MainStats.histogram_stats_skeleton(request)
    assert 10 == Enum.count(skeleton)

    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-05-10],
      interval: HistogramStatsRequest.interval(:month)
    }
    skeleton =
      request
      |> MainStats.histogram_intervals()
      |> MainStats.histogram_stats_skeleton(request)
    assert 5 == Enum.count(skeleton)

    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-01-10],
      interval: HistogramStatsRequest.interval(:month)
    }
    skeleton =
      request
      |> MainStats.histogram_intervals()
      |> MainStats.histogram_stats_skeleton(request)
    assert 1 == Enum.count(skeleton)
    assert %{
      "2017-01" => %{
        "interval" => %{
        "from_date" => "2017-01-01",
        "to_date" => "2017-01-10"
      }}
    } = skeleton

    request = %HistogramStatsRequest{
      from_date: ~D[2017-01-01],
      to_date: ~D[2017-05-10],
      interval: HistogramStatsRequest.interval(:year)
    }
    skeleton =
      request
      |> MainStats.histogram_intervals()
      |> MainStats.histogram_stats_skeleton(request)
    assert 1 == Enum.count(skeleton)
  end

  defp insert_fixtures do
    region = insert(:region)
    insert(:region, name: "ЧЕРКАСЬКА")
    person = insert(:person)
    insert(:legal_entity, addresses: [
          %{"zip": "02091", "area": "ЧЕРКАСЬКА",
            "type": "REGISTRATION", "region": "УМАНСЬКИЙ",
            "street": "вул. Ніжинська", "country": "UA",
            "building": "15", "apartment": "23",
            "settlement": "УМАНЬ", "street_type": "STREET",
            "settlement_id": "607dbc55-cb6b-4aaa-97c1-2a1e03476100",
            "settlement_type": "CITY"}
        ])
    legal_entity = insert(:legal_entity, addresses: [
      %{"zip": "02090", "area": "ЛЬВІВСЬКА",
        "type": "REGISTRATION", "region": "ПУСТОМИТІВСЬКИЙ",
        "street": "вул. Ніжинська", "country": "UA",
        "building": "15", "apartment": "23",
        "settlement": "СОРОКИ-ЛЬВІВСЬКІ", "street_type": "STREET",
        "settlement_id": "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
        "settlement_type": "CITY"},
    ])
    division = insert(:division, legal_entity_id: legal_entity.id)
    employee = insert(:employee,
      employee_type: "DOCTOR",
      division: division,
      legal_entity_id: legal_entity.id
    )
    insert(:employee, employee_type: "DOCTOR", legal_entity_id: legal_entity.id)
    insert(:employee)
    insert(:legal_entity)
    declaration1 = insert(:declaration,
      employee_id: employee.id,
      person_id: person.id,
      legal_entity_id: legal_entity.id,
      division_id: division.id,
      status: "active",
    )
    declaration2 = insert(:declaration,
      employee_id: employee.id,
      person_id: person.id,
      legal_entity_id: legal_entity.id,
      division_id: division.id,
      status: "terminated",
    )
    insert(:declaration_status_hstr, declaration_id: declaration1.id, status: declaration1.status)
    insert(:declaration_status_hstr, declaration_id: declaration1.id, status: "terminated")
    insert(:declaration_status_hstr, declaration_id: declaration1.id, status: declaration1.status)
    insert(:declaration_status_hstr, declaration_id: declaration2.id, status: declaration2.status)
    %{
      "region" => region,
      "division" => division,
      "legal_entity" => legal_entity,
      "employee" => employee,
      "declarations" =>[
        declaration1,
        declaration2,
      ],
    }
  end
end
