defmodule TransigoAdmin.Job.Helper do
  alias TransigoAdmin.{Account, DataLayer}
  alias TransigoAdmin.Account.{WebhookEvent, User}
  alias TransigoAdmin.{Credit, Credit.Transaction}
  alias SendGrid.{Mail, Email}

  require Logger

  # use TransigoAdmin.Job.Helper_API.Behaviour
  @behaviour TransigoAdmin.Job.HelperApi

  @doc """
  create webhook event and send to each users
  """
  @spec notify_api_users(map, String.t()) :: [tuple]
  def notify_api_users(result, event) do
    {:ok, webhook_event} =
      Account.create_webhook_event(%{
        message_uid: DataLayer.generate_uid("mes"),
        event: event,
        result: result
      })

    payload =
      %{
        event: event,
        result: result,
        metadata: %{
          messageUID: webhook_event.message_uid,
          currentDateTime: webhook_event.inserted_at,
          originalDateTime: webhook_event.inserted_at,
          retryNumber: 0
        }
      }
      |> Jason.encode!()

    Account.list_users()
    |> Enum.each(&send_webhook_event(&1, payload, webhook_event))
  end

  @doc """
  post webhook event to user
  """
  @spec post_webhook_event(User.t(), map) :: tuple
  def post_webhook_event(%User{webhook: nil}, _payload), do: {:error, :webhook_not_found}

  def post_webhook_event(%User{webhook: webhook}, payload),
    do: HTTPoison.post(webhook, payload, [{"Content-Type", "application/json"}])

  @doc """
  create webhook_user_event and send event to user
  when 200 status not received, mark as init_send_fail and let oban try again
  """
  @spec send_webhook_event(User.t(), String.t(), Webhook.t()) :: tuple
  def send_webhook_event(%User{id: user_id} = user, payload, %WebhookEvent{id: event_id}) do
    {:ok, user_event} =
      Account.create_webhook_user_event(%{user_id: user_id, webhook_event_id: event_id})

    case post_webhook_event(user, payload) do
      {:ok, %{status_code: 200}} ->
        Account.update_webhook_user_event(user_event, %{state: "success"})

      _ ->
        Account.update_webhook_user_event(user_event, %{state: "init_send_fail"})
    end
  end

  @doc """
  calculate the total sum from map [%{sum: number}]
  """
  @spec cal_total_sum(map) :: map
  def cal_total_sum(transactions),
    do:
      Enum.reduce(transactions, %{sum: 0}, fn %{sum: sum}, acc ->
        %{sum: acc.sum + sum}
      end)

  @doc """
  update transaction to the given state and return map
  """
  @spec move_transaction_to_state(Transaction.t(), atom) :: map | nil
  def move_transaction_to_state(%Transaction{} = transaction, state) do
    case Credit.update_transaction(transaction, %{transaction_state: state}) do
      {:ok, transaction} ->
        %{
          transactionUID: transaction.transaction_uid,
          sum: Float.round(transaction.financed_sum, 2)
        }
        |> put_datetime(transaction)

      {:error, _} ->
        nil
    end
  end

  @doc """
  put datetime to map base on the transaction's state
  """
  @spec put_datetime(map, Transaction.t()) :: map
  def put_datetime(result, %Transaction{transaction_state: :moved_to_payment} = transaction),
    do: Map.put(result, :transactionDateTime, transaction.down_payment_confirmed_datetime)

  def put_datetime(result, %Transaction{transaction_state: :rev_share_to_be_paid} = transaction),
    do: Map.put(result, :transactionDateTime, transaction.repaid_datetime)

  @doc """
  Transigo information fpr generating documents with doctools
  """
  @spec get_transigo_doc_info :: String.t()
  def get_transigo_doc_info do
    Jason.encode!(%{
      address: "7400 Beaufont Springs Drive, Suite 300 PMB#40025, Richmond, VA 23225, USA",
      contact: "Nir Tal",
      contact_email: "nir@transigo.io",
      name: "Transigo Transactions USA, LLC",
      phone: "888-783-6052",
      snail_mail:
        "Transigo Inc., 7400 Beaufont Springs Drive, Suite 300 PMB#40025 Richmond, VA 23225",
      support_email: "support@transigo.io"
    })
  end

  @doc """
  Send daily balance csv report
  """
  @spec send_report(Enumerable.t()) :: tuple
  def send_report(csv_stream) do
    {:ok, file} = Briefly.create(extname: ".csv", prefix: "daily_balance_report")

    csv_stream
    |> Enum.each(fn line ->
      File.write(file, line)
    end)

    {:ok, content} = File.read(file)

    # send file in email to Nir
    email_state =
      Email.build()
      |> Email.add_to("Nir@transigo.io")
      |> Email.put_from("tcaas@transigo.io", "Transigo")
      |> Email.put_subject("Daily Balance Report")
      |> Email.put_text("Please find the Daily Balance Report attached as a csv.")
      |> Email.add_attachment(%{
        content: Base.encode64(content),
        filename: Path.basename(file),
        type: "application/csv",
        disposition: "attachment"
      })
      |> Mail.send()

    Logger.info("The daily balance email state is -> #{email_state}")

    email_state
  end
end
