defmodule Report.Web.StatsView do
  @moduledoc false

  use Report.Web, :view

  def render("index.json", %{stats: stats}) do
    stats
  end

  def render("index.json", %{"division" => division, "stats" => stats}) do
    %{
      "division" => render_one(division, __MODULE__, "division.json"),
      "stats" => render_one(stats, __MODULE__, "index.json")
    }
  end

  def render("regions.json", %{stats: regions}) when is_list(regions) do
    render_many(regions, __MODULE__, "region_stat.json")
  end

  def render("region_stat.json", %{stats: %{"region" => region, "stats" => stats}}) do
    %{
      "region" => render_one(region, __MODULE__, "region.json"),
      "stats" => render_one(stats, __MODULE__, "index.json")
    }
  end

  def render("division.json", %{stats: division}) do
    %{
      "id" => division.id,
      "name" => division.name,
    }
  end

  def render("division_details.json", %{stats: division}) do
    %{
      "id" => division.id,
      "name" => division.name,
      "type" => division.type,
      "addresses" => division.addresses,
      "coordinates" => %{
        "latitude" => elem(division.location.coordinates, 0),
        "longitude" => elem(division.location.coordinates, 1),
      },
      "contacts" => %{
        "email" => division.email,
        "phones" => division.phones,
      }
    }
  end

  def render("region.json", %{stats: region}) do
    %{
      "id" => region.id,
      "name" => region.name,
    }
  end

  def render("region.json", stats) do
    stats
  end

  def render("divisions_map.json", %{divisions: divisions}) do
    render_many(divisions, __MODULE__, "division_details.json")
  end
end
