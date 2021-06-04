defmodule TransigoAdmin.PlaidRequest do
  use Oban.Worker, queue: :default, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"quota_id" => quota_id}}) do
    IO.inspect(quota_id)
    :ok
  end
end
