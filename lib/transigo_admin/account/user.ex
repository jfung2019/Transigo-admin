defmodule TransigoAdmin.Account.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "admins" do
    field :firstname, :string
    field :lastname, :string
    field :email, :string
    field :username, :string
    field :title, :string
    field :mobile, :string
    field :role, :string
    field :company, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :last_login, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :firstname,
      :lastname,
      :email,
      :username,
      :title,
      :mobile,
      :role,
      :company,
      :password,
      :last_login
    ])
    |> validate_required([
      :firstname,
      :lastname,
      :email,
      :username,
      :mobile,
      :role,
      :company,
      :password
    ])
    |> validate_length(:password, min: 6, max: 100)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> validate_format(:email, ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end
