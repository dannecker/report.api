use Mix.Config

# Configuration for test environment
config :ex_unit, capture_log: true

config :report_api, :environment, :test

# Configure your database
config :report_api, Report.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: {:system, "DB_NAME", "report_test"},
  ownership_timeout: 120_000_000

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :report_api, Report.Web.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Run acceptance test in concurrent mode
config :report_api, sql_sandbox: true
