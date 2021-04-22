defmodule TransigoAdminWeb.Api.Types.Credit do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias TransigoAdmin.{Account, Credit}

  object :quota do
    field :id, non_null(:id)
    field :quota_transigo_uid, non_null(:string)
    field :quota_usd, non_null(:float)
    field :credit_days_quota, non_null(:integer)
    field :credit_request_date, non_null(:date)
    field :token, non_null(:string)
    field :marketplace_transactions, non_null(:integer)
    field :marketplace_total_transaction_sum_usd, non_null(:float)
    field :marketplace_transactions_last_12_months, non_null(:integer)
    field :marketplace_total_transaction_sum_usd_last_12_months, non_null(:float)
    field :marketplace_number_disputes, non_null(:integer)
    field :marketplace_number_adverse_disputes, non_null(:integer)
    field :credit_status, non_null(:string)
    field :funding_source_url, :string
    field :credit_terms, non_null(:string)
    field :plaid_underwriting_result, :float
    field :eh_grade_job_url, :string
    field :importer, non_null(:importer), resolve: dataloader(Account)
  end

  connection(node_type: :quota)

  object :offer do
    field :id, non_null(:id)
    field :transaction_usd, non_null(:float)
    field :advance_percentage, non_null(:float)
    field :advance_usd, non_null(:float)
    field :importer_fee, non_null(:float)
    field :offer_accepted_declined, :string
    field :transaction, non_null(:transaction), resolve: dataloader(Credit)
  end

  connection(node_type: :offer)

  object :transaction do
    field :id, non_null(:id)
    field :transaction_uid, non_null(:string)
    field :credit_term_days, non_null(:integer)
    field :financier, non_null(:string)
    field :down_payment_usd, non_null(:float)
    field :down_payment_confirmed_datetime, :date
    field :factoring_fee_usd, non_null(:float)
    field :transaction_state, non_null(:string)
    field :financed_sum, non_null(:float)
    field :invoice_date, :date
    field :invoice_ref, :string
    field :po_date, :date
    field :po_ref, :string
    field :hellosign_signature_request_id, :string
    field :hs_signing_status, :string
    field :second_installment_usd, non_null(:float)
    field :repaid_datetime, :date
    field :dwolla_repayment_transfer_url, :string
    field :importer, non_null(:importer), resolve: dataloader(Account)
    field :exporter, non_null(:exporter), resolve: dataloader(Account)
  end

  connection(node_type: :transaction)
end