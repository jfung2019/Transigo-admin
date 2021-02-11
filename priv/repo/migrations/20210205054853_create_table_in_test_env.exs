defmodule TransigoAdmin.Repo.Migrations.CreateTableInTestEnv do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

    execute "ALTER TABLE users RENAME TO admins;"

    create_if_not_exists table("contact", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()")
      add :contact_transigoUID, :string
      add :first_name, :string
      add :last_name, :string
      add :mobile, :string
      add :work_phone, :string
      add :email, :string
      add :role, :string
      add :country, :string
      add :ssn, :string
      add :address, :string
      add :date_of_birth, :date

      timestamps(
        inserted_at: :created_datetime,
        updated_at: :last_modified_datetime,
        type: :utc_datetime
      )
    end

    create_if_not_exists table("importer", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()")
      add :importer_transigoUID, :string
      add :business_name, :string
      add :business_EIN, :string
      add :incorporation_date, :date
      add :importer_origin, :string, default: "DH"
      add :number_DUNS, :string
      add :business_address_street_address, :string
      add :business_address_city, :string
      add :business_address_state, :string
      add :business_address_zip, :string
      add :business_address_country, :string
      add :business_type, :string
      add :business_classification_id, :string
      add :contact_id, references(:contact, on_delete: :delete_all, type: :binary_id)

      timestamps(
        inserted_at: :created_datetime,
        updated_at: :last_modified_datetime,
        type: :utc_datetime
      )
    end

    create_if_not_exists table("marketplaces", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()")
      add :origin, :string
      add :marketplace, :string

      timestamps(
        inserted_at: :created_datetime,
        updated_at: :last_modified_datetime,
        type: :utc_datetime
      )
    end

    create_if_not_exists table("exporter", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()")
      add :exporter_transigoUID, :string
      add :business_name, :string
      add :address, :string
      add :business_address_country, :string
      add :registration_number, :string
      add :signatory_first_name, :string
      add :signatory_last_name, :string
      add :signatory_mobile, :string
      add :signatory_email, :string
      add :signatory_title, :string
      add :hellosign_signature_request_id, :string
      add :hs_signing_status, :string, default: "awaiting_signature"
      add :marketplace_id, references(:marketplaces, on_delete: :delete_all, type: :binary_id)

      timestamps(
        inserted_at: :created_datetime,
        updated_at: :last_modified_datetime,
        type: :utc_datetime
      )
    end

    create_if_not_exists table("quota", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("uuid_generate_v4()")
      add :quota_transigoUID, :string
      add :quota_USD, :float
      add :credit_days_quota, :integer
      add :credit_request_date, :date
      add :token, :string
      add :marketplace_transactions, :integer
      add :marketplace_total_transaction_sum_USD, :float
      add :marketplace_transactions_last_12_months, :integer
      add :marketplace_total_transaction_sum_USD_last_12_months, :float
      add :marketplace_number_disputes, :integer
      add :marketplace_number_adverse_disputes, :integer
      add :creditStatus, :string
      add :funding_source_url, :string
      add :credit_terms, :string
      add :importer_id, references(:importer, on_delete: :delete_all, type: :binary_id)

      timestamps(
        inserted_at: :created_datetime,
        updated_at: :last_modified_datetime,
        type: :utc_datetime
      )
    end

    create_if_not_exists table("transaction", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :transaction_UID, :string
      add :credit_term_days, :integer
      add :financier, :string, default: "Churchill"
      add :down_payment_USD, :float
      add :down_payment_confirmed_datetime, :utc_datetime
      add :factoring_fee_USD, :float
      add :transaction_state, :string, default: "xxx"
      add :financed_sum, :float
      add :invoice_date, :date
      add :invoice_ref, :string
      add :po_date, :date
      add :po_ref, :string
      add :hellosign_signature_request_id, :string
      add :hs_signing_status, :string, default: "awaiting_signature"
      add :second_installment_USD, :float
      add :repaid_datetime, :utc_datetime
      add :dwolla_repayment_transfer_url, :string
      add :importer_id, references(:importer, on_delete: :delete_all, type: :binary_id)
      add :exporter_id, references(:exporter, on_delete: :delete_all, type: :binary_id)

      timestamps(
        inserted_at: :created_datetime,
        updated_at: :last_modified_datetime,
        type: :utc_datetime
      )
    end

    create_if_not_exists table("users", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_uid, :string
      add :webhook, :string
      add :company, :string

      timestamps(
        inserted_at: :created_datetime,
        updated_at: :last_modified_datetime,
        type: :utc_datetime
      )
    end
  end
end
