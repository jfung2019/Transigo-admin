defmodule TransigoAdmin.ServiceManager.MeridianlinkBehavior do
  @callback update_contact_consumer_credit_report_by_quota_id(String.t()) ::
              :ok | {:error, String.t()}

  @callback update_contact_consumer_credit_report(String.t()) :: :ok | {:error, String.t()}

  @callback get_consumer_credit_report(struct(), struct()) :: :ok | {:error, String.t()}
end
