defmodule TransigoAdmin.Account.Guardian do
  use Guardian, otp_app: :transigo_admin

  alias TransigoAdmin.Account.User
  alias TransigoAdmin.Account

  def subject_for_token(%User{}= user, _claims), do: {:ok, "user:#{user.id}"}

  def subject_for_token(_resource, _claims), do: {:error, :reason_for_error}

  def resource_from_claims(%{"sub" => "user:" <> id}), do: {:ok, Account.get_user!(id)}

  def resource_from_claims(_claims), do: {:error, :reason_for_error}
end