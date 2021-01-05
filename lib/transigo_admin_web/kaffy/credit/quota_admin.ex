defmodule TransigoAdmin.Credit.QuotaAdmin do
  def index(_) do
    [
      quota_UID: nil,
      importer_id: nil,
      quota_USD: nil,
      credit_days_quota: nil,
      creditStatus: nil
    ]
  end

  def form_fields(_) do
    [
      quota_UID: nil,
      importer_id: nil,
      quota_USD: nil,
      credit_days_quota: nil,
      creditStatus: nil
    ]
  end
end
