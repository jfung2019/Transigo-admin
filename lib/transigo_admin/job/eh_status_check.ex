defmodule TransigoAdmin.Job.EhStatusCheck do
  use Oban.Worker, queue: :eh_status, max_attempts: 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "10_mins"}}) do

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "1_hours"}}) do

    :ok
  end
end