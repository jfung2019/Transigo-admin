defmodule TransigoAdmin.Credit.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "transaction" do

  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [])
    |> validate_required([])
  end
end
