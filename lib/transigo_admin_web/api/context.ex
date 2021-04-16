defmodule TransigoAdminWeb.Api.Context do
  @behaviour Plug
  import Plug.Conn
  require Logger

  alias TransigoAdmin.{Account, Account.Guardian}

  def init(opts), do: opts

  def call(conn, _), do: Absinthe.Plug.put_options(conn, context: build_context(conn))

  defp build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, admin} <- get_admin(token) do
      %{admin: admin}
    else
      _ ->
        %{}
    end
  end

  defp get_admin(token) do
    case Guardian.decode_and_verify(token) do
      {:ok, %{"sub" => "admin:" <> id}} ->
        try do
          {:ok, Account.get_admin!(id)}
        rescue
          exception ->
            Logger.warn(
              "API Context: Got valid token, but non-existing admin in db. #{inspect(exception)}"
            )

            :error
        end

      _ ->
        :error
    end
  end
end
