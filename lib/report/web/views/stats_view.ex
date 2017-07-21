defmodule Report.Web.StatsView do
  @moduledoc false

  use Report.Web, :view

  def render("index.json", %{"stats": stats}) do
    stats
  end

  def render("regions.json", %{"stats": stats}) do
    render_many(stats.regions, __MODULE__, "region.json")
  end

  def render("region.json", stats) do
    stats
  end
end
