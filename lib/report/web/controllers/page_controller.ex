defmodule Report.Web.PageController do
  @moduledoc """
  Sample controller for generated application.
  """
  use Report.Web, :controller

  action_fallback Report.Web.FallbackController

  def index(conn, _params) do
    render conn, "page.json"
  end
end
