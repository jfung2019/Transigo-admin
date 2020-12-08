defmodule TransigoAdminWeb.TransigoSignatureLive.Index do
  use TransigoAdminWeb, :live_view

  alias TransigoAdmin.Account

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :exporters, Account.list_awaiting_signature_exporter())}
  end
end