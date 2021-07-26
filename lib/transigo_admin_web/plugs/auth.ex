defmodule TransigoAdminWeb.Auth do
  @behaviour Plug

  alias TransigoAdmin.{Account, Account.Guardian}
  alias TransigoAdminWeb.Router.Helpers, as: Routes

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      %TransigoAdmin.Account.Admin{} = admin ->
        Plug.Conn.assign(conn, :admin, admin)

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(
          to:
            Routes.session_path(conn, :new,
              hellosign_signature_id: Map.get(conn.query_params, "hellosign_signature_id")
            )
        )
    end
  end

  @doc """
  Finds an user by email and password.
  """
  def sign_in_admin(email, given_pass, totp) do
    with admin <- Account.find_admin(email),
         true <- Account.check_password(admin, given_pass),
         :valid <- Account.validate_totp(admin, totp) do
      {:ok, admin}
    else
      _ -> {:error, :unauthorized}
    end
  end
end
