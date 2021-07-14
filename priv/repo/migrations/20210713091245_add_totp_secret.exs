defmodule TransigoAdmin.Repo.Migrations.AddTotpSecret do
  use Ecto.Migration

  def change do
    alter table("admins") do
      add :totp_secret, :bytea
    end
  end
end
