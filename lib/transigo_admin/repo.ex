defmodule TransigoAdmin.Repo do
  use Ecto.Repo,
    otp_app: :transigo_admin,
    adapter: Ecto.Adapters.Postgres
end
