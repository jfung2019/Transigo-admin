defmodule TransigoAdmin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      TransigoAdmin.Repo,
      # Start the Telemetry supervisor
      TransigoAdminWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TransigoAdmin.PubSub},
      # Start the Endpoint (http/https)
      TransigoAdminWeb.Endpoint
      # Start a worker by calling: TransigoAdmin.Worker.start_link(arg)
      # {TransigoAdmin.Worker, arg}
    ]

    events = [[:oban, :started], [:oban, :success], [:oban, :failed]]

    :telemetry.attach_many(
      "oban-logger",
      events,
      &TransigoAdmin.Job.ObanLogger.handle_event/4,
      []
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TransigoAdmin.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TransigoAdminWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
