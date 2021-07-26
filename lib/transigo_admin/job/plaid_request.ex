defmodule TransigoAdmin.PlaidRequest do
  @moduledoc """
  worker for getting all the information after the plaid form is completed
  """
  use Oban.Worker, queue: :default, max_attempts: 1

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"quota_id" => quota_id}}) do
    IO.inspect(quota_id)
    :ok
  end
end
