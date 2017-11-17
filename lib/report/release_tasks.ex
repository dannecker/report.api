defmodule Report.ReleaseTasks do
  @moduledoc """
  Nice way to apply migrations inside a released application.

  Example:

      report/bin/report command Elixir.Report.ReleaseTasks migrate!
  """
  alias Ecto.Migrator
  alias Ecto.Migration.Runner

  @start_apps [
    :logger,
    :postgrex,
    :ecto
  ]

  @apps [
    :report_api
  ]

  @repos [
    Report.Repo
  ]

  def migrate! do
    IO.puts "Loading report.."
    # Load the code for report, but don't start it
    :ok = Application.load(:report_api)

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for report
    IO.puts "Starting repos.."
    Enum.each(@repos, &(&1.start_link(pool_size: 1)))

    # Run migrations
    Enum.each(@apps, &run_migrations_for/1)

    # Run the seed script if it exists
    seed_script = seed_path(:report_api)
    if File.exists?(seed_script) do
      IO.puts "Running seed script.."
      Code.eval_file(seed_script)
    end

    # Signal shutdown
    IO.puts "Success!"
    :init.stop()
  end

  def priv_dir(app),
    do: :code.priv_dir(app)

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"
    Enum.each(@repos, &Migrator.run(&1, migrations_path(app), :up, all: true))
  end

  defp migrations_path(app),
    do: Path.join([priv_dir(app), "repo", "migrations"])

  defp seed_path(app),
    do: Path.join([priv_dir(app), "repo", "seeds.exs"])

  def setup_pg_logical! do
    pg_logical = Confex.get_env(:report_api, :pg_logical_node)
    Runner.execute "SELECT pglogical.create_node(
    node_name := ‘subscriber’,
    dsn := ‘#{pg_logical[:dsn]}’);"

    Runner.execute "SELECT pglogical.create_subscription(
    subscription_name := ‘subscription_mpi’,
    provider_dsn := ‘#{pg_logical[:mpi_dsn]}’);"

    Runner.execute "SELECT pglogical.create_subscription(
    subscription_name := ‘subscription_prm’,
    provider_dsn := ‘#{pg_logical[:prm_dsn]}’);"

    Runner.execute "SELECT pglogical.create_subscription(
    subscription_name := ‘subscription_uaddresses’,
    provider_dsn := ‘#{pg_logical[:uaddresses_dsn]}’);"

    Runner.execute "SELECT pglogical.create_subscription(
    subscription_name := ‘subscription_ops’,
    provider_dsn := ‘#{pg_logical[:ops_dsn]}’);"
  end
end
