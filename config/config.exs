# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :transigo_admin, TransigoAdmin.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "transigo",
  pool_size: 10

config :transigo_admin,
  ecto_repos: [TransigoAdmin.Repo],
  hs_client_id: System.get_env("TRANSIGO_HS_CLIENT_ID"),
  hs_api_key: System.get_env("TRANSIGO_HS_API_KEY")

# Configures the endpoint
config :transigo_admin, TransigoAdminWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "axpROzbFQlEV33Xqre2S62EtFq9x+o5c1mCHyb26ic+akrCGkCkyZpoSZugsbAqq",
  render_errors: [view: TransigoAdminWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: TransigoAdmin.PubSub,
  live_view: [signing_salt: "4C2SDiX1"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"