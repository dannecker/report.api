# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :report_api, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:report_api, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#
# Or read environment variables in runtime (!) as:
#
#     :var_name, "${ENV_VAR_NAME}"
config :report_api,
  ecto_repos: [Report.Repo]

# Configure your database
config :report_api, Report.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: {:system, "DB_NAME", "report_dev"},
  username: {:system, "DB_USER", "postgres"},
  password: {:system, "DB_PASSWORD", "postgres"},
  hostname: {:system, "DB_HOST", "localhost"},
  port: {:system, :integer, "DB_PORT", 5432},
  ownership_timeout: :infinity,
  pool_size: 20,
  types: Report.PostgresTypes
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
# Configures the endpoint
config :report_api, Report.Web.Endpoint,
  url: [host: "localhost"],
  load_from_system_env: true,
  secret_key_base: "U6jv7YneKVixSMz0h4Z/W1P5gifuhS0rekLu2tuZRsZmE856L71BcjX18tNzZmVu",
  render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]

config :report_api, :gandalf,
  url: {:system, "GANDALF_DECISION_URL", "http://localhost:4000"},
  user: {:system, "GANDALF_USER", "test"},
  password: {:system, "GANDALF_PASSWORD", "password"}

config :report_api,
  maturity_age: {:system, :integer, "MATURITY_AGE", 18},
  async_billing: true,
  validate_signed_content: {:system, :boolean, "VALIDATE_SIGNED_CONTENT", true}

config :ssl, protocol_version: :"tlsv1.2"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure JSON Logger back-end
config :logger_json, :backend,
  load_from_system_env: true,
  json_encoder: Poison,
  metadata: :all

config :report_api, Report.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", "http://api-svc.ael"},
  # endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", "http://0.0.0.0:64927"},
  capitation_report_bucket: {:system, "MEDIA_STORAGE_CAPITATION_REPORT_BUCKET", "capitation-reports-dev"},
  declarations_bucket: {:system, "MEDIA_STORAGE_DECLARATIONS_BUCKET", "declarations-dev"},
  enabled?: {:system, :boolean, "MEDIA_STORAGE_ENABLED", false},
  hackney_options: [
    connect_timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "MEDIA_STORAGE_REQUEST_TIMEOUT", 30_000}
  ]
# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env}.exs"
