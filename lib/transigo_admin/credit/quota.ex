defmodule TransigoAdmin.Credit.Quota do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  schema "quota" do
    belongs_to :importer, TransigoAdmin.Account.Importer
    field :quota_UID, :string
    field :quota_USD, :float
    field :credit_days_quota, :integer
    field :creditStatus, :string
    field :funding_source_url, :string

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @doc false
  def changeset(quota, attrs) do
    quota
    |> cast(attrs, [
      :importer_id,
      :quota_UID,
      :quota_USD,
      :credit_days_quota,
      :creditStatus,
      :funding_source_url
    ])
    |> validate_required([:importer_id, :quota_UID, :quota_USD, :credit_days_quota, :creditStatu])
  end
end
