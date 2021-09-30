defmodule TransigoAdmin.Job.EhStatusCheck do
  @moduledoc """
  check in quota for pending Euler Hermes jobs and save result if the job is finished by EH
  """
  use Oban.Worker, queue: :eh_status, max_attempts: 1

  alias TransigoAdmin.{Credit, Credit.Quota}
  alias TransigoAdmin.{Account, Account.Importer}
  #  alias SendGrid.{Mail, Email}

  @eh_api Application.compile_env(:transigo_admin, :eh_api)

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "10_mins"}}) do
    #    Account.list_importer_with_pending_eh_job()
    #    |> Enum.each(&check_eh_job(&1))

    Credit.list_quota_with_pending_eh_job()
    |> Enum.each(&check_eh_job(&1))

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "1_hours"}}) do
    #    Credit.list_quota_with_eh_cover()
    #    |> Enum.each(&check_cover_update(&1))

    :ok
  end

  #  defp check_eh_job(%Importer{eh_grade_job_url: job_url, eh_grade: nil} = importer) do
  #    {:ok, access_token} = @eh_api.eh_auth()
  #
  #    case @eh_api.eh_get(job_url, access_token) do
  #      {:ok, %{body: body, status_code: 200}} ->
  #        body
  #        |> Jason.decode()
  #        |> handle_job_result(importer, access_token)
  #
  #      _ ->
  #        nil
  #    end
  #  end

  defp check_eh_job(%Quota{eh_grade_job_url: job_url, eh_grade: nil} = quota) do
    {:ok, access_token} = @eh_api.eh_auth()

    case @eh_api.eh_get(job_url, access_token) do
      {:ok, %{body: body, status_code: 200}} ->
        body
        |> Jason.decode()
        |> handle_job_result(quota, access_token)

      _ ->
        nil
    end
  end

  #  defp check_cover_update(%Quota{eh_cover: %{"coverId" => cover_id}} = quota) do
  #    cover_url = "#{Application.get_env(:transigo_admin, :eh_risk_url)}/covers/#{cover_id}"
  #    {:ok, access_token} = @eh_api.eh_auth()
  #
  #    case @eh_api.eh_get(cover_url, access_token) do
  #      {:ok, %{body: body, status_code: 200}} ->
  #        body
  #        |> Jason.decode()
  #        |> handle_job_result(quota, access_token, :check)
  #
  #      {:error, _} ->
  #        nil
  #    end
  #  end

  defp handle_job_result(
         {:ok, %{"jobStatusCode" => "PROCESSED", "resourceUrl" => url}},
         schema,
         access_token
       ) do
    case @eh_api.eh_get(url, access_token) do
      {:ok, %{body: body, status_code: 200}} ->
        body
        |> Jason.decode()
        |> update_job_result(schema)

      _ ->
        nil
    end
  end

  #  defp handle_job_result(
  #         {:ok, %{"jobStatusCode" => "PROCESSED", "resourceUrl" => url}},
  #         %Quota{} = quota,
  #         access_token,
  #         :check
  #       ) do
  #    case @eh_api.eh_get(url, access_token) do
  #      {:ok, %{body: body, status_code: 200}} ->
  #        body
  #        |> Jason.decode(body)
  #        |> compare_old_new_eh_cover(quota)
  #
  #      _ ->
  #        nil
  #    end
  #  end

  defp update_job_result(
         {:ok, %{"requestStatus" => "ANSWERED"} = result},
         %Importer{} = importer
       ),
       do: Account.update_importer(importer, %{eh_grade: result})

  defp update_job_result(
         {:ok, %{"requestStatus" => "ANSWERED"} = result},
         %Quota{} = quota
       ) do
    # update the meridianlink fields on the contact waiting a max of 8 min for a response
    Task.Supervisor.async_nolink(TransigoAdmin.TaskSupervisor, TransigoAdmin.Meridianlink, :update_contact_consumer_credit_report_by_quota_id, [quota.id])
    |> Task.yield(480000)

    # update the eh_grade on the quota table kicking off the plaid underwriting
    Credit.update_quota(quota, %{eh_grade: result})
  end

  defp update_job_result(
         {:ok, %{"decision" => %{"permanent" => %{"permanentAmount" => eh_amount}}} = result},
         %Quota{plaid_underwriting_result: underwriting_amount} = quota
       ) do
    cond do
      eh_amount > underwriting_amount and underwriting_amount >= 5000 ->
        Credit.update_quota(quota, %{
          eh_cover: result,
          quota_USD: underwriting_amount,
          creditStatus: "granted"
        })

      eh_amount < underwriting_amount and eh_amount >= 5000 ->
        Credit.update_quota(quota, %{
          eh_cover: result,
          quota_USD: eh_amount,
          creditStatus: "granted"
        })

      true ->
        Credit.update_quota(quota, %{eh_cover: result, creditStatus: "rejected"})
    end
  end

  defp update_job_result({:ok, %{"coverStatusCode" => "Rejected"} = result}, %Quota{} = quota),
    do: Credit.update_quota(quota, %{eh_cover: result, creditStatus: "rejected"})

  defp update_job_result(_result, _schema), do: {:ok, :pass}

  #  defp send_email_to_importer({:ok, %Quota{importer_id: importer_id, creditStatus: "granted"}}) do
  #    contact = Account.get_contact_by_importer(importer_id)
  #    importer = Account.get_importer!(importer_id)
  #    kyc_url = "http://api.tcaas.app/v2/importers/#{importer.importer_transigoUID}/kyc"
  #    message = "<p>Quota is granted. Please click <a href='#{kyc_url}'>here</a> to continue.</p>"
  #
  #    Email.build()
  #    |> Email.put_from("tcaas@transigo.io", "Transigo")
  #    |> Email.add_to(contact.email)
  #    |> Email.put_subject("Transigo Quota Granted")
  #    |> Email.put_html(message)
  #    |> Mail.send()
  #  end
  #
  #  defp send_email_to_importer({:ok, %Quota{importer_id: importer_id, creditStatus: "rejected"}}) do
  #    contact = Account.get_contact_by_importer(importer_id)
  #    message = "<p>Quota is rejected.</p>"
  #
  #    Email.build()
  #    |> Email.put_from("tcaas@transigo.io", "Transigo")
  #    |> Email.add_to(contact.email)
  #    |> Email.put_subject("Transigo Quota Rejected")
  #    |> Email.put_html(message)
  #    |> Mail.send()
  #  end
  #
  #  defp send_email_to_importer(_tuple), do: :ok

  #  defp compare_old_new_eh_cover(
  #         %{"decision" => %{"decisionDate" => new_date}} = new_cover,
  #         %Quota{eh_cover: %{"decision" => %{"decisionDate" => old_date}}} = quota
  #       ) do
  #    if new_date != old_date, do: Credit.update_quota(quota, %{eh_cover: new_cover})
  #  end
end
