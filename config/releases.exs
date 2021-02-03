# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

config :transigo_admin, TransigoAdmin.Repo,
  # ssl: true,
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))

config :transigo_admin, TransigoAdminWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT", "4000")),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :transigo_admin,
  hs_client_id: System.get_env("TRANSIGO_HS_CLIENT_ID"),
  hs_api_key: System.get_env("TRANSIGO_HS_API_KEY"),
  dwolla_root_url: System.get_env("DWOLLA_ROOT_URL"),
  dwolla_client_id: System.get_env("DWOLLA_KEY"),
  dwolla_client_secret: System.get_env("DWOLLA_SECRET")

config :sendgrid,
  api_key: System.get_env("TRANSIGO_SENDGRID_API_KEY"),
  sandbox_enable: false

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :transigo_admin, TransigoAdminWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
