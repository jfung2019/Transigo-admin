defmodule TransigoAdmin.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field :webhook, :string
    field :company, :string
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:webhook, :company])
    |> validate_required([:company])
  end
end
