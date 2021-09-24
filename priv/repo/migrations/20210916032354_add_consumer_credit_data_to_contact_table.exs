defmodule TransigoAdmin.Repo.Migrations.AddConsumerCreditDataToContactTable do
  use Ecto.Migration

  def change do
    alter table "contact" do
      add :consumer_credit_score, :integer
      add :consumer_credit_score_percentile, :integer
      add :consumer_credit_report_meridianlink, :text
    end
  end

end
