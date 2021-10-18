defmodule TransigoAdmin.PostgresListener do
  use GenServer
  alias Postgrex.Notifications
  @plaid_request_channel "plaid_request"

  defstruct [:pid, :plaid_request_ref]

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    {:ok, pid} = Notifications.start_link(TransigoAdmin.Repo.config())
    plaid_request_ref = Notifications.listen!(pid, @plaid_request_channel)

    {:ok,
     %__MODULE__{
       pid: pid,
       plaid_request_ref: plaid_request_ref
     }}
  end

  def handle_info(
        {:notification, pid, ref, @plaid_request_channel, payload},
        %{pid: pid, plaid_request_ref: ref} = state
      ) do
    %{"id" => quota_id} = Jason.decode!(payload)

    %{"quota_id" => quota_id}
    |> TransigoAdmin.PlaidRequest.new()
    |> Oban.insert()

    {:noreply, state}
  end

  def terminate(_reason, %{pid: pid, plaid_request_ref: plaid_request_ref}) do
    Notifications.unlisten!(pid, plaid_request_ref)
    :ok
  end
end
