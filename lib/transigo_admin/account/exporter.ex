defmodule TransigoAdmin.Account.Exporter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, read_after_writes: true}
  schema "exporter" do
    field :exporter_transigoUID, :string
    field :business_name, :string
    field :hellosign_signature_request_id, :string
    field :hs_signing_status, :string
  end

  @doc false
  def changeset(exporter, attrs) do
    exporter
    |> cast(attrs, [:exporter_transigoUID, :business_name, :hellosign_signature_request_id, :hs_signing_status])
    |> validate_required([:exporter_transigoUID, :business_name, :hellosign_signature_request_id, :hs_signing_status])
  end
end