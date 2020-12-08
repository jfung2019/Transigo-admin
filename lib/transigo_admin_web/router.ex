defmodule TransigoAdminWeb.Router do
  use TransigoAdminWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TransigoAdminWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin_authenticated do
    plug TransigoAdminWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TransigoAdminWeb do
    pipe_through :browser

    live "/", PageLive, :index

    scope "/admin" do
      resources "/sessions", SessionController, only: [:new, :create, :delete]

      scope "/" do
        live "/awaiting_exporter", TransigoSignatureLive.Index, :index
        resources "/signing", HellosignController, only: [:index]
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TransigoAdminWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: TransigoAdminWeb.Telemetry
    end
  end
end
