defmodule TransigoAdminWeb.Api.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  alias TransigoAdminWeb.Api.{Resolvers, Types}

  import_types(Types.Account)
  import_types(Types.Credit)
  import_types(Types.Helpers)

  query do
    @desc "list exporters paginated"
    connection field :list_exporters, node_type: :exporter do
      resolve(&Resolvers.Account.list_exporters/3)
    end

    @desc "list importers paginated"
    connection field :list_importers, node_type: :importer do
      resolve(&Resolvers.Account.list_importers/3)
    end

    @desc "list quotas paginated"
    connection field :list_quotas, node_type: :quota do
      resolve(&Resolvers.Credit.list_quotas/3)
    end

    @desc "list offers paginated"
    connection field :list_offers, node_type: :offer do
      resolve(&Resolvers.Credit.list_offers/3)
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
