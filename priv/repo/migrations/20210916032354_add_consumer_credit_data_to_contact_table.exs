defmodule TransigoAdmin.Repo.Migrations.AddConsumerCreditDataToContactTable do
  use Ecto.Migration

  def up do
    alter table "contact" do
      add :consumer_credit_score, :integer
      add :consumer_credit_score_percentile, :integer
      add :consumer_credit_report_meridianlink, :text
    end
  end

  def down do
    alter table "contact" do
      remove :consumer_credit_score
      remove :consumer_credit_score_percentile
      remove :consumer_credit_report_meridianlink
    end
  end
end
