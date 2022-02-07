defmodule TransigoAdmin.Repo.Migrations.ChangePlaidUnderwritingToArray do
  use Ecto.Migration

  def change do
    alter table("quota") do
      modify :plaid_underwriting_signals, :jsonb, default: "[]"
    end

    execute "UPDATE quota
    SET plaid_underwriting_signals = '[]'::json
    WHERE plaid_underwriting_signals::text = '{}'",
            "UPDATE quota
    SET plaid_underwriting_signals = '{}'::json
    WHERE plaid_underwriting_signals::text = '[]'"
  end
end
