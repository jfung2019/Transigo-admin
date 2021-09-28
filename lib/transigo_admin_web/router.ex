defmodule TransigoAdminWeb.Router do
  use TransigoAdminWeb, :router

  pipeline :browser do
    plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TransigoAdminWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin_authenticated do
    plug TransigoAdminWeb.Guardian.AuthPipeline
    plug TransigoAdminWeb.Auth
  end

  pipeline :api do
    plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
    plug :accepts, ["json"]
  end

  pipeline :absinthe_api do
    plug TransigoAdminWeb.Api.Context
  end

  pipeline :api_auth do
    plug TransigoAdminWeb.ApiAuth
  end

  scope "/", TransigoAdminWeb do
    pipe_through :browser

    resources "/importers_signup", ImporterFormController, only: [:new, :create]
    resources "/sessions", SessionController, only: [:new, :create], singleton: true

    scope "/admin" do
      pipe_through :admin_authenticated

      get "/sessions", SessionController, :index, as: :logged_in_session
      get "/signing", HellosignController, :index
    end
  end

  scope "/v2", TransigoAdminWeb.Api do
    pipe_through [:api, :api_auth]

    scope "/exporters" do
      scope "/:exporter_uid" do
        post "/", ExporterController, :create_exporter
        get "/:exporter_uid", ExporterController, :show_exporter
        put "/:exporter_uid", ExporterController, :update_exporter
        get "/:exporter_uid/get_msa", ExporterController, :get_msa

        get "/:exporter_uid/sign_transaction/:transaction_uid",
            ExporterController,
            :sign_transaction

        get "/sign_msa", ExporterController, :sign_msa
      end
    end

    scope "/trans" do
      post "/generate_offer", OfferController, :generate_offer

      scope "/:transaction_uid" do
        get "/offer", OfferController, :get_offer
        post "/accept", OfferController, :accept_decline_offer
        post "/confirm_downpayment", OfferController, :confirm_downpayment
        get "/sign_docs", OfferController, :sign_docs
        get "/get_tran_docs", OfferController, :get_tran_doc
      end
    end

    scope "/invoices/:transaction_uid" do
      post "/upload_invoice", OfferController, :upload_invoice
      post "/upload_PO", OfferController, :upload_po
    end
  end

  # Other scopes may use custom stacks.
  scope "/" do
    pipe_through [:api, :absinthe_api]

    forward "/api", Absinthe.Plug, schema: TransigoAdminWeb.Api.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: TransigoAdminWeb.Api.Schema,
      socket: TransigoAdminWeb.UserSocket,
      context: %{pubsub: TransigoAdminWeb.Endpoint}
  end

  scope "/" do
    get "/health-check", TransigoAdminWeb.HealthCheckController, :health_check
  end

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
