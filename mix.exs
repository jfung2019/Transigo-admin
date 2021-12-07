defmodule TransigoAdmin.MixProject do
  use Mix.Project

  def project do
    [
      app: :transigo_admin,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TransigoAdmin.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.6"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.14.6"},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.3 or ~> 0.2.9"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:argon2_elixir, "~> 2.3"},
      {:httpoison, "~> 1.8"},
      {:guardian, "~> 2.0"},
      {:oban, "~> 2.4.2"},
      {:sendgrid, "~> 2.0"},
      {:timex, "~> 3.0"},
      {:absinthe, "~> 1.6.3"},
      {:absinthe_plug, "~> 1.5.7"},
      {:absinthe_phoenix, "~> 2.0.1"},
      {:absinthe_relay, "~> 1.5.1"},
      {:dataloader, "~> 1.0.8"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:sweet_xml, "~> 0.6.6"},
      {:hackney, "~> 1.18"},
      {:sentry, "~> 8.0"},
      {:briefly, "~> 0.3"},
      {:nimble_totp, "~> 0.1.2"},
      {:puid, "~> 1.0"},
      {:google_maps, "~> 0.11"},
      {:fuzzy_compare, "~> 1.0"},
      {:address_us, github: "smashedtoatoms/address_us"},
      {:ecto_commons, "~> 0.3.3"},
      {:tesla, "~> 1.4"},
      {:mox, "~> 0.5.2", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
