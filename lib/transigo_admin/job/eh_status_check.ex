defmodule TransigoAdmin.Job.EhStatusCheck do
  use Oban.Worker, queue: :eh_status, max_attempts: 5

  alias TransigoAdmin.{Credit, Credit.Quota}
  alias TransigoAdmin.{Account, Account.Importer}

  @eh_api Application.compile_env(:transigo_admin, :eh_api)

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "10_mins"}}) do
    {:ok, access_token} = @eh_api.eh_auth()

    Account.list_importer_with_pending_eh_job()
    |> Enum.each(&check_eh_job(&1, access_token))

    Credit.list_quota_with_pending_eh_job()
    |> Enum.each(&check_eh_job(&1, access_token))

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => "1_hours"}}) do
    {:ok, access_token} = @eh_api.eh_auth()

    Credit.list_quota_with_eh_cover()
    |> Enum.each(&check_cover_update(&1, access_token))

    :ok
  end

  defp check_eh_job(%Importer{eh_grade_job_url: job_url, eh_grade: nil} = importer, access_token) do
    case @eh_api.eh_get(job_url, access_token) do
      {:ok, %{body: body, status_code: 200}} ->
        body
        |> Jason.decode()
        |> handle_job_result(importer, access_token)

      _ ->
        nil
    end
  end

  defp check_eh_job(%Quota{eh_cover_job_url: job_url, eh_cover: nil} = quota, access_token) do
    case @eh_api.eh_get(job_url, access_token) do
      {:ok, %{body: body, status_code: 200}} ->
        body
        |> Jason.decode()
        |> handle_job_result(quota, access_token)

      {:error, _} ->
        nil
    end
  end

  defp check_cover_update(%Quota{eh_cover: %{"coverId" => cover_id}} = quota, access_token) do
    cover_url = "#{Application.get_env(:transigo_admin, :eh_root_url)}/covers/#{cover_id}"

    case @eh_api.eh_get(cover_url, access_token) do
      {:ok, %{body: body, status_code: 200}} ->
        body
        |> Jason.decode()
        |> handle_job_result(quota, access_token, :check)

      {:error, _} ->
        nil
    end
  end

  defp handle_job_result(
         {:ok, %{"jobStatusCode" => "PROCESSED", "resourceUrl" => url}},
         schema,
         access_token
       ) do
    case @eh_api.eh_get(url, access_token) do
      {:ok, %{body: body, status_code: 200}} ->
        body
        |> Jason.decode(body)
        |> update_job_result(schema)

      _ ->
        nil
    end
  end

  defp handle_job_result(
         {:ok, %{"jobStatusCode" => "PROCESSED", "resourceUrl" => url}},
         %Quota{} = quota,
         access_token,
         :check
       ) do
    case @eh_api.eh_get(url, access_token) do
      {:ok, %{body: body, status_code: 200}} ->
        body
        |> Jason.decode(body)
        |> compare_old_new_eh_cover(quota)

      _ ->
        nil
    end
  end

  defp update_job_result({:ok, result}, %Importer{} = importer),
    do: Account.update_importer(importer, %{eh_grade: result})

  defp update_job_result({:ok, result}, %Quota{} = quota),
    do: Credit.update_quota(quota, %{eh_cover: result})

  defp compare_old_new_eh_cover(
         %{"decision" => %{"decisionDate" => new_date}} = new_cover,
         %Quota{eh_cover: %{"decision" => %{"decisionDate" => old_date}}} = quota
       ) do
    if new_date != old_date, do: Credit.update_quota(quota, %{eh_cover: new_cover})
  end
end
