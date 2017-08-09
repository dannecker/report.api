use Mix.Config

# Configuration for test environment


# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :report_api, Report.Web.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.

config :phoenix, :stacktrace_depth, 20

config :report_api,
  validate_signed_content: false

config :report_api, Report.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: {:system, "DB_NAME", "report"},
  username: {:system, "DB_USER", "db"},
  password: {:system, "DB_PASSWORD", ""},
  hostname: {:system, "DB_HOST", "0.0.0.0"},
  port: {:system, :integer, "DB_PORT", 54321}
