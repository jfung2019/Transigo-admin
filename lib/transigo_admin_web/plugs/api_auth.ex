defmodule TransigoAdminWeb.ApiAuth do
  @behaviour Plug

  @error_view TransigoAdminWeb.ApiErrorView

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with ["Bearer " <> token] <- Plug.Conn.get_req_header(conn, "authorization"),
         :ok <- check_token(token) do
      conn
    else
      _ ->
        conn
        |> Plug.Conn.halt()
        |> Plug.Conn.put_status(403)
        |> Phoenix.Controller.put_view(@error_view)
        |> Phoenix.Controller.render("errors.json", message: "Unauthorized request")
    end
  end

  defp check_token(token) do
    case TransigoAdmin.Account.get_token_id(token) do
      nil -> :error
      _ -> :ok
    end
  end
end
