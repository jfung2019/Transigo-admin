defmodule TransigoAdminWeb.Api.Context do
  @behaviour Plug
  require Logger

  def init(opts), do: opts

  def call(conn, _), do: Absinthe.Plug.put_options(conn, context: %{})
end
