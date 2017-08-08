defmodule Report.Integration.DivisionStatsTest do
  @moduledoc false

  use Report.Web.ConnCase

  alias Report.Replica.Division
  alias Report.Stats.DivisionStats
  alias Report.Stats.DivisionsMapRequest
  alias Scrivener.Page

  test "get_map_stats/1" do
    %{"division" => division} = insert_fixtures()
    params = %{
      name: division.name,
      type: DivisionsMapRequest.type(:clinic),
      lefttop_latitude: 35,
      lefttop_longitude: 45,
      rightbottom_latitude: 25,
      rightbottom_longitude: 55,
    }

    {:ok, %Page{entries: map_stats}} = DivisionStats.get_map_stats(params)
    assert 1 == Enum.count(map_stats)

    id = division.id
    assert [%Division{id: ^id}] = map_stats

    {:ok, %Page{entries: []}} = DivisionStats.get_map_stats(Map.put(params, :page, 2))
  end

  defp insert_fixtures do
    legal_entity = insert(:legal_entity)
    params = [
      legal_entity_id: legal_entity.id,
      location: %Geo.Point{coordinates: {30.1233, 50.32423}},
      type: DivisionsMapRequest.type(:clinic),
      status: "ACTIVE",
      is_active: true,
      name: "test name",
    ]
    division = insert(:division, params)
    insert(:division, Keyword.put(params, :is_active, false))
    %{
      "division" => division,
      "legal_entity" => legal_entity,
    }
  end
end
