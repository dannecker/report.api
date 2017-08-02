defmodule Report.Stats.DivisionStats do
  @moduledoc false

  alias Geo.WKT
  alias Report.Repo
  alias Report.Replica.Division
  alias Report.Stats.DivisionsMapRequest

  import Ecto.Query
  import Ecto.Changeset
  import Report.Replica.Replicas
  import Report.Stats.DivisionStatsValidator

  def get_map_stats(params) do
    with %Ecto.Changeset{valid?: true} = changeset <- divisions_map_changeset(%DivisionsMapRequest{}, params),
         divisions_map_request <- apply_changes(changeset),
         divisions <- divisions_by_map_request(divisions_map_request)
      do
      {:ok, divisions}
    end
  end

  defp divisions_by_map_request(%DivisionsMapRequest{} = request) do
    %{
      lefttop_latitude: lefttop_latitude,
      lefttop_longitude: lefttop_longitude,
      rightbottom_latitude: rightbottom_latitude,
      rightbottom_longitude: rightbottom_longitude,
      type: type,
      name: name} = request

    polygon = WKT.encode(
      %Geo.Polygon{coordinates: [[
        {lefttop_latitude, lefttop_longitude},
        {lefttop_latitude, rightbottom_longitude},
        {rightbottom_latitude, rightbottom_longitude},
        {rightbottom_latitude, lefttop_longitude},
        {lefttop_latitude, lefttop_longitude}
      ]]}
    )

    Division
    |> params_query(%{"type" => type, "status" => "ACTIVE", "is_active" => true})
    |> ilike_query(:name, name)
    |> where([d], fragment("ST_Intersects(?, ST_GeomFromText(?))", d.location, ^polygon))
    |> Repo.all
  end
end
