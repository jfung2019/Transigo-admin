defmodule TransigoAdmin.Job.Helper do
  alias TransigoAdmin.{Account, Account.User}
  alias TransigoAdmin.{Credit, Credit.Transaction}

  def notify_api_users(result, event) do
    payload =
      %{
        event: event,
        result: result
      }
      |> Jason.encode!()

    Account.list_users_with_webhook()
    |> Enum.each(&post_webhook_event(&1, payload))
  end

  defp post_webhook_event(%User{webhook: webhook}, payload),
    do: HTTPoison.post(webhook, payload, [{"Content-Type", "application/json"}])

  def format_webhook_result(transactions) do
    total =
      Enum.reduce(transactions, %{sum: 0}, fn %{sum: sum}, acc ->
        %{sum: acc.sum + sum}
      end)

    %{
      totalRemitSum: total.sum,
      dailyTransaction: transactions
    }
  end

  def move_transaction_to_state(%Transaction{} = transaction, state) do
    case Credit.update_transaction(transaction, %{transaction_state: state}) do
      {:ok, transaction} ->
        %{
          transctionUID: transaction.transaction_UID,
          sum: Float.round(transaction.financed_sum, 2),
          transactionDateTime: transaction.repaid_datetime
        }

      {:error, _} ->
        nil
    end
  end

  def dwolla_auth() do
    url = "#{Application.get_env(:transigo_admin, :dwolla_root_url)}/token"

    client_id = Application.get_env(:transigo_admin, :dwolla_client_id)
    client_secret = Application.get_env(:transigo_admin, :dwolla_client_secret)

    base64_token =
      "#{client_id}:#{client_secret}"
      |> Base.encode64()

    basic_auth_token = "Basic #{base64_token}"

    payload = {:form, [{"grant_type", "client_credentials"}]}

    response =
      HTTPoison.post(url, payload, [
        {"Content-Type", "application/x-www-form-urlencoded"},
        {"Authorization", basic_auth_token}
      ])

    case response do
      {:ok, %{body: body}} ->
        %{"access_token" => access_token} = Jason.decode!(body)

        {:ok, access_token}

      {:error, _} = error_tuple ->
        error_tuple
    end
  end

  def dwolla_post(path, access_token, body) do
    url = "#{Application.get_env(:transigo_admin, :dwolla_root_url)}/#{path}"
    payload = Jason.encode!(body)

    HTTPoison.post(url, payload, [
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Content-Type", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "Bearer #{access_token}"}
    ])
  end

  def dwolla_get(url, access_token) do
    HTTPoison.get(url, [
      {"Accept", "application/vnd.dwolla.v1.hal+json"},
      {"Authorization", "Bearer #{access_token}"}
    ])
  end
end
