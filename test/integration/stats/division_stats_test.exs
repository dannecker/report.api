defmodule Report.Integration.DivisionStatsTest do
  @moduledoc false

  use Report.Web.ConnCase

  alias Report.Replica.Division
  alias Report.Stats.DivisionStats
  alias Report.Stats.DivisionsMapRequest
  alias Scrivener.Page

  describe "get_map_stats/1" do
    test "search clinics" do
      %{"division" => division} = insert_fixtures()
      params = %{
        name: division.name,
        type: DivisionsMapRequest.type(:clinic),
        lefttop_longitude: 25,
        lefttop_latitude: 45,
        rightbottom_longitude: 35,
        rightbottom_latitude: 55,
      }

      {:ok, %Page{entries: map_stats}} = DivisionStats.get_map_stats(params)
      assert 1 == Enum.count(map_stats)

      id = division.id
      assert [%Division{id: ^id}] = map_stats

      {:ok, %Page{entries: []}} = DivisionStats.get_map_stats(Map.put(params, :page, 2))
    end

    test "search drugstores" do
      insert_fixtures()
      drugstore = DivisionsMapRequest.type(:drugstore)
      params = %{
        type: drugstore,
        lefttop_longitude: 25,
        lefttop_latitude: 45,
        rightbottom_longitude: 35,
        rightbottom_latitude: 55,
      }

      {:ok, %Page{entries: map_stats}} = DivisionStats.get_map_stats(params)
      assert 1 == Enum.count(map_stats)

      assert [%Division{type: ^drugstore}] = map_stats

      {:ok, %Page{entries: []}} = DivisionStats.get_map_stats(Map.put(params, :page, 2))
    end
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
    insert(:division, Keyword.put(params, :type, DivisionsMapRequest.type(:drugstore)))
    %{
      "division" => division,
      "legal_entity" => legal_entity,
    }
  end
end
