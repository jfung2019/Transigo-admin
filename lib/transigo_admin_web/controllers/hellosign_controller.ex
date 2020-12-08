defmodule TransigoAdminWeb.HellosignController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account

  def index(conn, %{"exporter_id" => exporter_id} = _param) do
    Account.get_exporter_signing_url(exporter_id)
    conn =
      conn
      |> assign(:hs_client_id, Application.get_env(:transigo_admin, :hs_client_id))
      |> assign(:sign_url, Account.get_exporter_signing_url(exporter_id))
    render(conn, "index.html")
  end
end