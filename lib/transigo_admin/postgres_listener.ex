defmodule TransigoAdmin.PostgresListener do
  use GenServer
  alias Postgrex.Notifications
  @plaid_request_channel "plaid_request"
  @quota_created_channel "quota_created"

  defstruct [:pid, :plaid_request_ref, :quota_created_ref]

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    {:ok, pid} = Notifications.start_link(TransigoAdmin.Repo.config())
    plaid_request_ref = Notifications.listen!(pid, @plaid_request_channel)
    quota_created_ref = Notifications.listen!(pid, @quota_created_channel)

    {:ok,
     %__MODULE__{
       pid: pid,
       plaid_request_ref: plaid_request_ref,
       quota_created_ref: quota_created_ref
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

  def handle_info(
        {:notification, pid, ref, @quota_created_channel, payload},
        %{pid: pid, quota_created_ref: ref} = state
      ) do
    %{"message" => %{"id" => quota_id}} = Jason.decode!(payload)
    TransigoAdmin.Meridianlink.update_contact_consumer_credit_report_by_quota_id(quota_id)
    {:noreply, state}
  end

  def terminate(_reason, %{pid: pid, plaid_request_ref: plaid_request_ref}) do
    Notifications.unlisten!(pid, plaid_request_ref)
    :ok
  end
end
