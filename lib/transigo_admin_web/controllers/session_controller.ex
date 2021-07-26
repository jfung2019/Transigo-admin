defmodule TransigoAdminWeb.SessionController do
  use TransigoAdminWeb, :controller
  alias TransigoAdminWeb.Auth
  alias TransigoAdmin.Account.{Admin, Guardian}

  def new(conn, params) do
    signature_id = Map.get(params, "hellosign_signature_id")

    case Guardian.Plug.current_resource(conn) do
      %Admin{} ->
        conn
        |> redirect_index_or_sign(signature_id)

      _ ->
        conn
        |> render("new.html", hellosign_signature_id: Map.get(params, "hellosign_signature_id"))
    end
  end

  def create(conn, %{
        "session" => %{"email" => email, "password" => password, "totp" => totp} = session
      }) do
    signature_id = Map.get(session, "hellosign_signature_id")

    case Auth.sign_in_admin(email, password, totp) do
      {:ok, admin} ->
        conn
        |> Guardian.Plug.sign_in(admin, %{}, ttl: {10, :minutes})
        |> redirect_index_or_sign(signature_id)

      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "*Bad email/password/TOTP")
        |> render("new.html", hellosign_signature_id: signature_id)
    end
  end

  def index(conn, _params), do: render(conn, "index.html")

  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> redirect(to: Routes.session_path(conn, :new))
  end

  defp redirect_index_or_sign(conn, nil),
    do: redirect(conn, to: Routes.logged_in_session_path(conn, :index))

  defp redirect_index_or_sign(conn, ""),
    do: redirect(conn, to: Routes.logged_in_session_path(conn, :index))

  defp redirect_index_or_sign(conn, signature_id),
    do:
      redirect(conn, to: Routes.hellosign_path(conn, :index, hellosign_signature_id: signature_id))
end
