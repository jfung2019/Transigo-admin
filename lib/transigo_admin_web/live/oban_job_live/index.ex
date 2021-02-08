defmodule TransigoAdminWeb.ObanJobLive.Index do
  use TransigoAdminWeb, :live_view

  alias TransigoAdmin.Account

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :jobs, Account.list_oban_jobs())}
  end
end
