defmodule TransigoAdminWeb.SessionController do
  use TransigoAdminWeb, :controller
  alias TransigoAdminWeb.Auth

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case Auth.sign_in_user(email, password) do
      {:ok, user} ->
        conn
        |> Auth.login(user)
        |> redirect(to: Routes.kaffy_home_path(conn, :index))

      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "*Bad email/password")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Auth.logout()
    |> redirect(to: Routes.session_path(conn, :new))
  end
end
