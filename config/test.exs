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
  # port: {:system, :integer, "DB_PORT", 5432}
  ownership_timeout: 120_000_000

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :report_api, Report.Web.Endpoint,
  http: [port: 4001],
  server: true
config :report_api,
  async_billing: false
# Run acceptance test in concurrent mode
config :report_api, sql_sandbox: true
config :logger, :console, format: "[$level] $message\n"
config :logger, level: :info
config :ex_unit, capture_log: true

config :report_api, mock: [
  port: {:system, :integer, "TEST_MOCK_PORT", 4040},
  host: {:system, "TEST_MOCK_HOST", "localhost"}
]

config :report_api, Report.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", "http://localhost:4040"}
