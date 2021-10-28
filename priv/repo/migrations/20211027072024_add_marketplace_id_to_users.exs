defmodule TransigoAdmin.Repo.Migrations.AddMarketplaceIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :marketplace_id, references(:marketplaces, on_delete: :delete_all, type: :binary_id)
    end
  end
end
