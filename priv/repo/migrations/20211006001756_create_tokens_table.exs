defmodule TransigoAdmin.Repo.Migrations.CreateTokensTable do
  use Ecto.Migration

  def change do
    create_if_not_exists table("tokens", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :access_token, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(
        inserted_at: :created_datetime,
        updated_at: :last_modified_datetime,
        type: :utc_datetime
      )
    end
  end
end
