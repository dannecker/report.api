defmodule Report.Web.Router do
  use Report.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Report.Web do
    pipe_through :api
  end
end
