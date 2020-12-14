defmodule TransigoAdminWeb.Auth do
  @behaviour Plug

  alias TransigoAdmin.Account
  alias TransigoAdmin.Account.Guardian
  alias TransigoAdminWeb.Router.Helpers, as: Routes

  import Argon2, only: [verify_pass: 2, no_user_verify: 0]

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      %TransigoAdmin.Account.User{} ->
        conn

      _ ->
        conn
        |> Plug.Conn.halt()
        |> Phoenix.Controller.redirect(to: Routes.session_path(conn, :new))
    end
  end

  @doc """
  Logs in an admin user by setting the session.
  """
  def login(conn, user) do
#    hi = Guardian.Plug.sign_in(conn, user)
#    IO.inspect(hi)
#    hi
    Guardian.Plug.sign_in(conn, user)
  end

  def logout(conn) do
    Guardian.Plug.sign_out(conn)
  end

  @doc """
  Finds an user by email and password.
  """
  def sign_in_user(email, given_pass) do
    with user <- Account.find_user(email),
         true <- check_password(user, given_pass) do
      {:ok, user}
    else
      _ -> {:error, :unauthorized}
    end
  end

  defp check_password(nil, _password), do: no_user_verify()
  defp check_password(user, password), do: verify_pass(password, user.password_hash)
end
