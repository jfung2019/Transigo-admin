defmodule TransigoAdmin.GuardianErrorHandler do
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]
  alias TransigoAdminWeb.Router.Helpers, as: Routes

  def auth_error(conn, _error_tuple, _opts) do
    conn
    |> put_flash(:info, "Please login")
    |> redirect(
      to:
        Routes.session_path(conn, :new,
          hellosign_signature_id: Map.get(conn.query_params, "hellosign_signature_id")
        )
    )
  end
end
