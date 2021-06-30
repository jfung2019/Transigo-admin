defmodule TransigoAdmin.Repo.Migrations.AddCnMsaToExporter do
  use Ecto.Migration

  def change do
    alter table(:exporter) do
      add :cn_msa, :boolean, null: false, default: false
    end
  end
end
