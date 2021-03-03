defmodule TransigoAdmin.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :user_uid, :string
    field :webhook, :string
    field :company, :string
    field :client_id, :string
    field :client_secret, :string

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_uid, :webhook, :company, :client_id, :client_secret])
    |> validate_required([:user_uid, :company, :client_id, :client_secret])
  end
end
