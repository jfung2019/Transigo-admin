defmodule TransigoAdminWeb.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline,
      otp_app: :transigo_admin,
      module: TransigoAdmin.Account.Guardian

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.LoadResource, allow_blank: true
end
