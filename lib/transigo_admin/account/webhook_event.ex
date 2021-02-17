defmodule TransigoAdmin.Account.WebhookEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "webhook_events" do
    field :event, :string
    field :result, :map

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @doc false
  def changeset(webhook_event, attrs) do
    webhook_event
    |> cast(attrs, [:event, :result])
    |> validate_required([:event, :result])
  end
end
