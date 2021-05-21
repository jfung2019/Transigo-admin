defmodule TransigoAdmin.Repo.Migrations.CreateUserTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", "DROP EXTENSION citext"

    create table(:admins, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :firstname, :string, null: false
      add :lastname, :string, null: false
      add :email, :citext, null: false
      add :username, :string, null: false
      add :title, :string, null: true
      add :mobile, :string, null: false
      add :role, :string, null: false
      add :company, :string, null: false
      add :password_hash, :text, null: false
      add :last_login, :naive_datetime, null: true

      timestamps()
    end

    create unique_index(:admins, [:email])
    create unique_index(:admins, [:username])
  end
end
