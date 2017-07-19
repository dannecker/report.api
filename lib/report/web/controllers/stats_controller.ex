defmodule Report.Web.StatsController do
  @moduledoc false

  use Report.Web, :controller

  alias Report.Stats.MainStats

  action_fallback Report.Web.FallbackController

  def index(conn, params) do
    with {:ok, main_stats} <- MainStats.get_main_stats(params)
    do
      render(conn, "index.json", stats: main_stats)
    end
  end
end
