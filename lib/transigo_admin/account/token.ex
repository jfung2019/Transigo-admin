defmodule TransigoAdmin.Account.Token do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "tokens" do
    field :access_token
    belongs_to :user, TransigoAdmin.Account.User

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:access_token, :user_id])
    |> validate_required([:access_token])
  end
end
