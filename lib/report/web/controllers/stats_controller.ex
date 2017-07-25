defmodule Report.Web.StatsController do
  @moduledoc false

  use Report.Web, :controller

  alias Report.Stats.MainStats

  action_fallback Report.Web.FallbackController

  def index(conn, params) do
    with {:ok, main_stats} <- MainStats.get_main_stats(params) do
      render(conn, "index.json", stats: main_stats)
    end
  end

  def divisions(conn, %{"id" => id} = params) do
    with {:ok, main_stats} <- MainStats.get_division_stats(id) do
      render(conn, "index.json", stats: main_stats)
    end
  end

  def regions(conn, params) do
    with {:ok, main_stats} <- MainStats.get_regions_stats(params) do
      render(conn, "index.json", stats: main_stats)
    end
  end

  def histogram(conn, params) do
    with {:ok, main_stats} <- MainStats.get_histogram_stats(params) do
      render(conn, "index.json", stats: main_stats)
    end
  end
end
