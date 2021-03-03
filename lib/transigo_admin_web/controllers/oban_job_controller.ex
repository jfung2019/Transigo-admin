defmodule TransigoAdminWeb.ObanJobController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account

  def index(conn, _param) do
    conn
    |> assign(:jobs, Account.list_oban_jobs())
    |> render("index.html")
  end
end
