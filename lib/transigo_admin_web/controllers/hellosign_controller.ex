defmodule TransigoAdminWeb.HellosignController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account

  def index(conn, %{"signature_request_id" => signature_request_id} = _param) do
    case Account.get_signing_url(signature_request_id) do
      {:ok, sign_url} ->
        conn =
          conn
          |> assign(:hs_client_id, Application.get_env(:transigo_admin, :hs_client_id))
          |> assign(:sign_url, sign_url)

        render(conn, "index.html")

      {:error, error} ->
        IO.inspect(error)
        render(conn, "failed.html")
    end
  end
end
