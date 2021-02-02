defmodule TransigoAdmin.Job.DailyBalance do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
  end
end
