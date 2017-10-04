defmodule Report.Web.ReimbursementController do
  @moduledoc false

  use Report.Web, :controller

  alias Report.Stats.ReimbursementStats
  alias Scrivener.Page

  action_fallback Report.Web.FallbackController

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with %Page{} = paging <- ReimbursementStats.get_stats(params, headers) do
      render(conn, "index.json", stats: paging.entries, paging: paging)
    end
  end
end
