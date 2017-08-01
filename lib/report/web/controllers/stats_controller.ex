defmodule Report.Web.StatsController do
  @moduledoc false

  use Report.Web, :controller

  alias Report.Stats.DivisionStats
  alias Report.Stats.MainStats

  action_fallback Report.Web.FallbackController

  def index(conn, _params) do
    with {:ok, main_stats} <- MainStats.get_main_stats() do
      render(conn, "index.json", stats: main_stats)
    end
  end

  def division(conn, %{"id" => id}) do
    with {:ok, main_stats} <- MainStats.get_division_stats(id) do
      render(conn, "index.json", main_stats)
    end
  end

  def regions(conn, _) do
    with {:ok, main_stats} <- MainStats.get_regions_stats() do
      render(conn, "regions.json", stats: main_stats)
    end
  end

  def histogram(conn, params) do
    with {:ok, main_stats} <- MainStats.get_histogram_stats(params) do
      render(conn, "index.json", stats: main_stats)
    end
  end

  def divisions_map(conn, params) do
    with {:ok, map_stats} <- DivisionStats.get_map_stats(params) do
      render(conn, "divisions_map.json", divisions: map_stats)
    end
  end
end
