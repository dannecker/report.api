use Mix.Config

# Configure your database
config :report_api, Report.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: {:system, "DB_NAME", "report_test"},
  # adapter: Ecto.Adapters.Postgres,
  # database: {:system, "DB_NAME", "report_test"},
  # username: {:system, "DB_USER", "postgres"},
  # password: {:system, "DB_PASSWORD", "postgres"},
  # hostname: {:system, "DB_HOST", "0.0.0.0"},
  # port: {:system, :integer, "DB_PORT", 5432},
  ownership_timeout: 120_000_000

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :report_api, Report.Web.Endpoint,
  http: [port: 4001],
  server: true

config :report_api, :gandalf,
  url: {:system, "GANDALF_DECISION_URL", "http://localhost:4000"},
  user: {:system, "GANDALF_USER", "test"},
  password: {:system, "GANDALF_PASSWORD", "password"}

# Run acceptance test in concurrent mode
config :report_api, sql_sandbox: true
config :logger, :console, format: "[$level] $message\n"
config :logger, level: :info
config :ex_unit, capture_log: true
