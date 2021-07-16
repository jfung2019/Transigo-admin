defmodule TransigoAdminWeb.HellosignController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account

  def index(conn, %{"signature_request_id" => signature_request_id} = _param) do
    Account.get_signing_url(signature_request_id)
    |> render_page(conn)
  end

  def index(conn, %{"signature_id" => signature_id} = _param) do
    Account.get_signing_url_by_sign_id(signature_id)
    |> render_page(conn)
  end

  defp render_page({:ok, sign_url}, conn) do
    conn
    |> assign(:hs_client_id, Application.get_env(:transigo_admin, :hs_client_id))
    |> assign(:sign_url, sign_url)
    |> render("index.html")
  end

  defp render_page({:error, _}, conn), do: render(conn, "failed.html")
end
