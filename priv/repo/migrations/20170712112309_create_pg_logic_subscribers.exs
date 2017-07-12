defmodule Report.Repo.Migrations.CreatePgLogicSubscribers do
  use Ecto.Migration

  def up do
    if  Application.get_env(:report_api, :environment) == :prod do
      pg_logical = Confex.get(:report_api, :pg_logical_node)
      execute "SELECT pglogical.create_node(
      node_name := ‘subscriber’,
      dsn := ‘#{pg_logical[:dsn]}’);"

      execute "SELECT pglogical.create_subscription(
      subscription_name := ‘subscription_mpi’,
      provider_dsn := ‘#{pg_logical[:mpi_dsn]}’);"

      execute "SELECT pglogical.create_subscription(
      subscription_name := ‘subscription_prm’,
      provider_dsn := ‘#{pg_logical[:prm_dsn]}’);"

      execute "SELECT pglogical.create_subscription(
      subscription_name := ‘subscription_uaddresses’,
      provider_dsn := ‘#{pg_logical[:uaddresses_dsn]}’);"

      execute "SELECT pglogical.create_subscription(
      subscription_name := ‘subscription_ops’,
      provider_dsn := ‘#{pg_logical[:ops_dsn]}’);"
    end
  end

  def down do
  end
end
