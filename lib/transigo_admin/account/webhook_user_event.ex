defmodule TransigoAdmin.Account.WebhookUserEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "webhook_user_events" do
    field :retry_number, :integer, default: 0
    field :state, :string, default: "init"

    belongs_to :webhook_event, TransigoAdmin.Account.WebhookEvent
    belongs_to :user, TransigoAdmin.Account.User

    timestamps(
      inserted_at_source: :created_datetime,
      updated_at_source: :last_modified_datetime,
      type: :utc_datetime
    )
  end

  @doc false
  def changeset(webhook_user_event, attrs) do
    webhook_user_event
    |> cast(attrs, [:retry_number, :state, :webhook_event_id, :user_id])
    |> validate_required([:retry_number, :state, :webhook_event_id, :user_id])
  end
end
