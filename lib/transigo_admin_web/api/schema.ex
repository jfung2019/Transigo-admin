defmodule TransigoAdminWeb.Api.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  alias TransigoAdminWeb.Api.{Resolvers, Types, Middleware}

  import_types Types.Account
  import_types Types.Credit
  import_types Types.Helpers

  mutation do
    @desc "login"
    field :login, non_null(:admin_session) do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      arg :totp, non_null(:string)
      resolve &Resolvers.Account.login/3
    end
  end

  query do
    @desc "list exporters paginated"
    connection field :list_exporters, node_type: :exporter do
      arg :keyword, :string
      arg :hs_signing_status, :string
      middleware Middleware.Authenticate
      resolve &Resolvers.Account.list_exporters/3
    end

    @desc "list importers paginated"
    connection field :list_importers, node_type: :importer do
      arg :keyword, :string
      middleware Middleware.Authenticate
      resolve &Resolvers.Account.list_importers/3
    end

    @desc "list quotas paginated"
    connection field :list_quotas, node_type: :quota do
      arg :keyword, :string
      arg :credit_status, :string
      middleware Middleware.Authenticate
      resolve &Resolvers.Credit.list_quotas/3
    end

    @desc "list transactions paginated"
    connection field :list_transactions, node_type: :transaction do
      arg :keyword, :string
      arg :hs_signing_status, :string
      arg :transaction_status, :string
      middleware Middleware.Authenticate
      resolve &Resolvers.Credit.list_transactions/3
    end

    @desc "list offers paginated"
    connection field :list_offers, node_type: :offer do
      arg :keyword, :string
      arg :accepted, :boolean
      middleware Middleware.Authenticate
      resolve &Resolvers.Credit.list_offers/3
    end
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(TransigoAdmin.Account, TransigoAdmin.Account.datasource())
      |> Dataloader.add_source(TransigoAdmin.Credit, TransigoAdmin.Credit.datasource())

    Map.put(ctx, :loader, loader)
  end

  def plugins, do: [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
end
