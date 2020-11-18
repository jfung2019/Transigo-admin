defmodule TransigoAdmin.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :firstname, :string
    field :lastname, :string
    field :email, :string
    field :username, :string
    field :title, :string
    field :mobile, :string
    field :role, :string
    field :company, :string
    field :last_login, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [])
    |> validate_required([])
  end
end
