defmodule TransigoAdmin.Repo.Migrations.TransactionAddHellosignAssignmentSignatureRequestId do
  use Ecto.Migration

  def change do
    alter table("transaction") do
      add :hellosign_assignment_signature_request_id, :string
    end
  end
end
