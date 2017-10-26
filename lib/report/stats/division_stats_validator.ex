defmodule Report.Stats.DivisionStatsValidator do
  @moduledoc false

  import Ecto.Changeset

  alias Report.Stats.DivisionsMapRequest

  @fields_divisions_map ~w(
    type
    name
    lefttop_latitude
    lefttop_longitude
    rightbottom_latitude
    rightbottom_longitude
  )a

  @fields_required_divisions_map ~w(
    lefttop_latitude
    lefttop_longitude
    rightbottom_latitude
    rightbottom_longitude
  )a

  def divisions_map_changeset(%DivisionsMapRequest{} = divisions_map_request, params) do
    geo_format = [less_than_or_equal_to: 90, greater_than_or_equal_to: -90]

    divisions_map_request
    |> cast(params, @fields_divisions_map)
    |> validate_required(@fields_required_divisions_map)
    |> validate_number(:lefttop_latitude, geo_format)
    |> validate_number(:lefttop_longitude, geo_format)
    |> validate_number(:rightbottom_latitude, geo_format)
    |> validate_number(:rightbottom_longitude, geo_format)
    |> validate_inclusion(:type, DivisionsMapRequest.types())
  end
end
