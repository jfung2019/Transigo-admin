defmodule TransigoAdmin.Credit.Quota do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "quota" do
    belongs_to :importer, TransigoAdmin.Account.Importer
    field :quota_UID, :string
    field :quota_USD, :decimal
    field :credit_days_quota, :integer
    field :creditStatus, :string
  end

  @doc false
  def changeset(quota, attrs) do
    quota
    |> cast(attrs, [:importer_id, :quota_UID, :quota_USD, :credit_days_quota, :creditStatus])
    |> validate_required([:importer_id, :quota_UID, :quota_USD, :credit_days_quota, :creditStatu])
  end
end
