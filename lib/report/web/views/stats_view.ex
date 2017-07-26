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

  def render("index.json", %{"region" => region, "stats" => stats}) do
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

  def render("region.json", %{stats: region}) do
    %{
      "id" => region.id,
      "name" => region.name,
    }
  end

  def render("region.json", stats) do
    stats
  end
end
