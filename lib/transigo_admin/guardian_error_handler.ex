defmodule TransigoAdmin.GuardianErrorHandler do
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]
  alias TransigoAdminWeb.Router.Helpers, as: Routes

  def auth_error(conn, {_type, _reason} = error_tuple, _opts) do
    conn
    |> put_flash(:info, "Please login")
    |> redirect(to: Routes.session_path(conn, :new))
  end
end
