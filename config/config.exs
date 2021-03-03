# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :transigo_admin, TransigoAdmin.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10

config :transigo_admin,
  ecto_repos: [TransigoAdmin.Repo],
  hs_client_id: System.get_env("TRANSIGO_HS_CLIENT_ID"),
  hs_api_key: System.get_env("TRANSIGO_HS_API_KEY"),
  dwolla_api: TransigoAdmin.ServiceManager.Dwolla.DwollaApi,
  dwolla_root_url: System.get_env("DWOLLA_ROOT_URL"),
  dwolla_client_id: System.get_env("DWOLLA_KEY"),
  dwolla_client_secret: System.get_env("DWOLLA_SECRET"),
  dwolla_master_funding_source: System.get_env("DWOLLA_MASTER_FUNDING_SOURCE"),
  util_api: TransigoAdmin.ServiceManager.Util.UtilApi,
  uid_util_url: System.get_env("UID_UTIL_URL"),
  eh_api_key: System.get_env("TRANSIGO_EH_KEY"),
  eh_root_url: "",
  eh_api: TransigoAdmin.ServiceManager.EulerHermes.EhApi

config :kaffy,
  otp_app: :transigo_admin,
  user_title: "Transigo Admin",
  hide_dashboard: false,
  home_page: [kaffy: :dashboard],
  ecto_repo: TransigoAdmin.Repo,
  router: TransigoAdminWeb.Router,
  resources: &TransigoAdmin.KaffyConfig.create_resources/1

config :transigo_admin, Oban,
  repo: TransigoAdmin.Repo,
  queues: [default: 20, transaction: 20, webhook: 20, eh_status: 20],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 21600},
    {Oban.Plugins.Cron,
     timezone: "Asia/Hong_Kong",
     crontab: [
       {"0 0 * * *", TransigoAdmin.Job.DailyRepayment},
       {"0 0 * * *", TransigoAdmin.Job.DailyBalance},
       {"0 0 1 * *", TransigoAdmin.Job.MonthlyRevShare},
       {"* * * * *", TransigoAdmin.Job.WebhookResend, args: %{state: "init_send_fail"}},
       {"0 * * * *", TransigoAdmin.Job.WebhookResend, args: %{state: "first_resend_fail"}},
       {"0 0 * * *", TransigoAdmin.Job.WebhookResend, args: %{state: "second_resend_fail"}}
       #       {"*/10 * * * *", TransigoAdmin.Job.EhStatusCheck, args: %{type: "10_mins"}},
       #       {"0 * * * *", TransigoAdmin.Job.EhStatusCheck, args: %{type: "1_hours"}}
     ]}
  ]

config :transigo_admin, TransigoAdmin.Account.Guardian,
  issuer: "transigo_admin",
  secret_key: "qKYyE2p3xQGqjO5Bs4LxPu7xr9IV4qCYLM9oXrzuTvnGOaCZm4YIl2O8CBPQeTnR",
  ttl: {52, :weeks},
  max_age: {78, :weeks}

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

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
