import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :transigo_admin, TransigoAdmin.Repo,
  username: "postgres",
  password: "postgres",
  database: "transigo_admin_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: System.get_env("DB_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :transigo_admin, TransigoAdminWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :transigo_admin, Oban, crontab: false, queues: false, prune: :disabled

config :sendgrid,
  api_key: System.get_env("TRANSIGO_SENDGRID_API_KEY", "API_KEY"),
  sandbox_enable: true

config :transigo_admin,
  dwolla_api: TransigoAdmin.ServiceManager.Dwolla.DwollaApiMock
