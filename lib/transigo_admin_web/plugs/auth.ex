defmodule TransigoAdminWeb.Auth do
  @behaviour Plug

  alias TransigoAdmin.{Account, Account.Guardian}
  alias TransigoAdminWeb.Router.Helpers, as: Routes

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      %TransigoAdmin.Account.Admin{} ->
        conn

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: Routes.session_path(conn, :new))
    end
  end

  @doc """
  Finds an user by email and password.
  """
  def sign_in_admin(email, given_pass) do
    with user <- Account.find_admin(email),
         true <- Account.check_password(user, given_pass) do
      {:ok, user}
    else
      _ -> {:error, :unauthorized}
    end
  end
end
