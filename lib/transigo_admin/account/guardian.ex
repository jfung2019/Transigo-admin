defmodule TransigoAdmin.Account.Guardian do
  use Guardian, otp_app: :transigo_admin

  alias TransigoAdmin.Account.Admin
  alias TransigoAdmin.Account

  def subject_for_token(%Admin{} = admin, _claims), do: {:ok, "admin:#{admin.id}"}

  def subject_for_token(_resource, _claims), do: {:error, :reason_for_error}

  def resource_from_claims(%{"sub" => "admin:" <> id}), do: {:ok, Account.get_admin!(id)}

  def resource_from_claims(_claims), do: {:error, :reason_for_error}
end
