defmodule TransigoAdmin.Credit.QuotaAdmin do
  def index(_) do
    [
      quota_transigo_uid: nil,
      importer_id: nil,
      quota_usd: nil,
      credit_days_quota: nil,
      credit_request_date: nil,
      token: nil,
      marketplace_transactions: nil,
      marketplace_total_transaction_sum_usd: nil,
      marketplace_transactions_last_12_months: nil,
      marketplace_total_transaction_sum_usd_last_12_months: nil,
      marketplace_number_disputes: nil,
      marketplace_number_adverse_disputes: nil,
      creditStatus: nil,
      funding_source_url: nil,
      credit_terms: nil,
      inserted_at: %{name: "created datetime"},
      updated_at: %{name: "last modified datetime"}
    ]
  end

  def form_fields(_) do
    [
      quota_transigo_uid: nil,
      importer_id: nil,
      quota_USD: nil,
      credit_days_quota: nil,
      credit_request_date: nil,
      token: nil,
      marketplace_transactions: nil,
      marketplace_total_transaction_sum_usd: nil,
      marketplace_transactions_last_12_months: nil,
      marketplace_total_transaction_sum_usd_last_12_months: nil,
      marketplace_number_disputes: nil,
      marketplace_number_adverse_disputes: nil,
      creditStatus: nil,
      funding_source_url: nil,
      credit_terms: nil,
      inserted_at: %{name: "created datetime"},
      updated_at: %{name: "last modified datetime"}
    ]
  end
end
