defmodule TransigoAdminWeb.Auth do
  @behaviour Plug
  @key :user_id

  alias TransigoAdmin.Account
  alias TransigoAdminWeb.Router.Helpers, as: Routes

  import Argon2, only: [verify_pass: 2, no_user_verify: 0]

  import Plug.Conn,
         only: [configure_session: 2, put_session: 3, get_session: 2, halt: 1, assign: 3]

  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    if user_id = get_session(conn, @key) do
      assign(conn, :current_user, Account.get_user!(user_id))
    else
      conn
      |> redirect(to: Routes.session_path(conn, :new))
      |> put_flash(:error, "Please login")
      |> halt()
    end
  end

  @doc """
  Logs in an admin user by setting the session.
  """
  def login(conn, user) do
    conn
    |> put_session(@key, user.id)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    conn
    |> Plug.Conn.clear_session()
    |> configure_session(drop: true)
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
