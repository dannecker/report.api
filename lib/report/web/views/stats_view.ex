defmodule Report.Web.StatsView do
  @moduledoc false

  use Report.Web, :view

  def render("index.json", %{"stats": stats}) do
    stats
  end
end
