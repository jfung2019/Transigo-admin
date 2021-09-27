# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

config :transigo_admin, TransigoAdmin.Repo,
  # ssl: true,
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))

config :transigo_admin, TransigoAdminWeb.Endpoint,
  url: [host: System.get_env("ENDPOINT_HOST")],
  http: [
    port: String.to_integer(System.get_env("PORT", "4000")),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :transigo_admin,
  hs_api: TransigoAdmin.ServiceManager.HelloSign.HsApi,
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
  eh_auth_url: System.get_env("EH_AUTH_URL"),
  eh_api: TransigoAdmin.ServiceManager.EulerHermes.EhApi,
  dev_user_id: System.get_env("DEV_USER_ID"),
  api_domain: System.get_env("API_DOMAIN"),
  s3_api: TransigoAdmin.ServiceManager.S3.S3Api,
  s3_bucket_name: System.get_env("S3_BUCKET_NAME"),
  doctools_url: System.get_env("DOCTOOLS_URL"),
  meridianlink_authorization: System.get_env("MERIDIANLINK_AUTH"),
  meridianlink_mcl_interface: System.get_env("MERIDIANLINK_MCL_INTERFACE"),
  encryption_salt: System.get_env("ENCRYPTION_SALT")

config :sendgrid,
  api_key: System.get_env("TRANSIGO_SENDGRID_API_KEY"),
  sandbox_enable: false

config :google_maps,
  api_key: System.get_env("TRANSIGO_GOOGLE_MAPS_API_KEY")

config :ex_aws,
  json_codec: Jason,
  region: "us-west-2",
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role]

config :sentry,
  dsn: System.get_env("SENTRY_ELIXIR_DNS"),
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{env: "production"},
  included_environments: [:prod]

config :logger,
  backends: [:console, Sentry.LoggerBackend]

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :transigo_admin, TransigoAdminWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
