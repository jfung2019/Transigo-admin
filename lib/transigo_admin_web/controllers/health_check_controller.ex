defmodule TransigoAdminWeb.HealthCheckController do
  use TransigoAdminWeb, :controller

  def health_check(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> text("")
  end
end