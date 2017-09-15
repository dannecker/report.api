defmodule Report do
  @moduledoc """
  This is an entry point of report application.
  """
  use Application
  alias Report.Web.Endpoint
  alias Confex.Resolver

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Configure Logger severity at runtime
    "LOG_LEVEL"
    |> System.get_env()
    |> configure_log_level()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Report.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Report.Web.Endpoint, []),
      # Starts a worker by calling: Report.Worker.start_link(arg1, arg2, arg3)
      # worker(Report.Worker, [arg1, arg2, arg3]),
      worker(Report.Scheduler, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Report.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  # Configures Logger level via LOG_LEVEL environment variable.
  # Configures Logger level via LOG_LEVEL environment variable.
  @doc false
  def configure_log_level(nil),
    do: :ok
  def configure_log_level(level) when level in ["debug", "info", "warn", "error"],
    do: Logger.configure(level: String.to_atom(level))
  def configure_log_level(level),
    do: raise ArgumentError, "LOG_LEVEL environment should have one of 'debug', 'info', 'warn', 'error' values," <>
                             "got: #{inspect level}"

  # Loads configuration in `:init` callbacks and replaces `{:system, ..}` tuples via Confex
  @doc false
  def init(_key, config), do: {:ok, Resolver.resolve!(config)}
end
