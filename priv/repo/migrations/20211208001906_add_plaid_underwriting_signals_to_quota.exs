defmodule TransigoAdmin.Repo.Migrations.AddPlaidUnderwritingSignalsToQuota do
  use Ecto.Migration

  def change do
    alter table("quota") do
      add :plaid_underwriting_signals, :map, default: %{}
    end
  end
end
