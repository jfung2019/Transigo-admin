defmodule TransigoAdminWeb.HellosignController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account

  def index(conn, %{"token" => token}) do
    case TransigoAdminWeb.Tokenizer.decrypt(token) do
      {:ok, signature_request_id} ->
        Account.get_signing_url(signature_request_id)
        |> render_page(conn)

      {:error, :expired} ->
        render(conn, "expired.html")
    end
  end

  defp render_page({:ok, sign_url}, conn),
    do:
      render(conn, "index.html",
        hs_client_id: Application.get_env(:transigo_admin, :hs_client_id),
        sign_url: sign_url
      )

  defp render_page({:error, _}, conn), do: render(conn, "failed.html")
end
