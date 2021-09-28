defmodule TransigoAdminWeb.HealthCheckControllerTest do
  use TransigoAdminWeb.ConnCase, async: true

  test "get 200 response", %{conn: conn} do
    conn = get(conn, "/health-check")
    assert html_response(conn, 200) == ""
  end
end
