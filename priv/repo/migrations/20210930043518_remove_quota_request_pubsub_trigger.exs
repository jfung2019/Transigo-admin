defmodule TransigoAdmin.Repo.Migrations.RemoveQuotaRequestPubsubTrigger do
  use Ecto.Migration

  def change do
    execute """
    DROP FUNCTION IF EXISTS notify_quota_created() CASCADE
    """

    execute """
    DROP TRIGGER IF EXISTS notify_quota_created ON quota CASCADE
    """
  end
end
