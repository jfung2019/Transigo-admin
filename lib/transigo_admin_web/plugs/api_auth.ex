defmodule TransigoAdminWeb.ApiAuth do
  @behaviour Plug

  @error_view TransigoAdminWeb.ApiErrorView

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with ["Bearer " <> token] <- Plug.Conn.get_req_header(conn, "authorization"),
         %TransigoAdmin.Account.Token{} = token <- check_token(token) do
      conn
      |> Plug.Conn.assign(:marketplace, token.user.marketplace)
      |> Plug.Conn.assign(:user, token.user)
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
    case TransigoAdmin.Account.get_user_and_marketplace_by_token(token) do
      nil -> :error
      token -> token
    end
  end
end
