defmodule TransigoAdmin.Account.Guardian do
  use Guardian, otp_app: :transigo_admin
  alias TransigoAdmin.Account.User
  alias TransigoAdmin.Account

  def subject_for_token(%User{}= user, _claims) do
    {:ok, "user:#{user.id}"}
  end

  def resource_from_claims(%{"sub" => "user:" <> id}) do
    {:ok, Account.get_user!(id)}
  end
end