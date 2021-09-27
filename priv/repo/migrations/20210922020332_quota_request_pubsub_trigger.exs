defmodule TransigoAdmin.Repo.Migrations.QuotaRequestPubsubTrigger do
  use Ecto.Migration

  def change do
    execute """
    CREATE OR REPLACE FUNCTION notify_quota_created()
    RETURNS trigger AS $$
    BEGIN
    PERFORM pg_notify(
      'quota_created',
      json_build_object(
        'message', json_build_object('id', NEW.id)
      )::text
    );
    RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;
    """,
    "DROP FUNCTION IF EXISTS notify_quota_created()"

    execute """
    CREATE TRIGGER notify_quota_created
    AFTER INSERT
    ON quota
    FOR EACH ROW
    EXECUTE PROCEDURE notify_quota_created();
    """,
    "DROP TRIGGER IF EXISTS notify_quota_created()"

  end
end
