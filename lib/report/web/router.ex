defmodule Report.Web.Router do
  @moduledoc """
  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """
  use Report.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :put_secure_browser_headers

    # Uncomment to enable versioning of your API
    # plug Multiverse, gates: [
    #   "2016-07-31": Report.Web.InitialGate
    # ]

    # You can allow JSONP requests by uncommenting this line:
    # plug :allow_jsonp
  end

  scope "/", Report.Web do
    pipe_through :api

    scope "/reports" do
      scope "/stats" do
        get "/", StatsController, :index
        get "/divisions/map", StatsController, :divisions_map
        get "/division/:id", StatsController, :division
        get "/regions", StatsController, :regions
        get "/histogram", StatsController, :histogram
      end

      scope "/log" do
        get "/", ReportLogsController, :index
        get "/temp_capitation", ReportLogsController, :temp_capitation
      end
    end

    get "/page", PageController, :index
  end
end
