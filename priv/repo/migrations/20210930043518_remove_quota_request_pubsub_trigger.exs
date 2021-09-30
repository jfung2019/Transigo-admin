defmodule TransigoAdmin.Repo.Migrations.RemoveQuotaRequestPubsubTrigger do
  use Ecto.Migration

  def change do
    execute """
    DROP FUNCTION IF EXISTS notify_quota_created()
    """

    execute """
    DROP TRIGGER IF EXISTS notify_quota_created ON quota
    """

  end
end
