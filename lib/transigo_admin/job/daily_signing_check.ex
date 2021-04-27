defmodule TransigoAdmin.Job.DailySigningCheck do
  use Oban.Worker, queue: :default, max_attempts: 5

  alias TransigoAdmin.{Account, Job.Helper}

  @hs_api Application.compile_env(:transigo_admin, :hs_api)
  @util_api Application.compile_env(:transigo_admin, :util_api)

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Account.list_unsigned_exporters()
    |> Enum.map(&check_signature_overdue(&1))
    |> Enum.reject(fn result ->
      case result do
        nil -> true
        {:error, _} -> true
        _ -> false
      end
    end)
    |> webhook_result()

    :ok
  end

  defp check_signature_overdue(%{hellosign_signature_request_id: hs_request_id} = exporter) do
    case @hs_api.get_signature_request(hs_request_id) do
      {:ok, %{"signature_request" => %{"created_at" => created_at}}} ->
        DateTime.from_unix!(created_at, :second)
        |> Timex.diff(Timex.now(), :month)
        |> regenerate_msa(exporter)

      _ ->
        nil
    end
  end

  def regenerate_msa(created_diff, exporter) do
    cond do
      created_diff <= -1 ->
        %{}
        |> @util_api.generate_exporter_msa(exporter.exporter_transigo_uid)
        |> create_hs_request(exporter)

      true ->
        nil
    end
  end

  defp create_hs_request({:ok, msa_path}, exporter) do
    case @hs_api.create_signature_request(msa_path, exporter) do
      {:ok, %{body: body}} ->
        # update exporter
        :ok

      _ ->
        nil
    end
  end

  defp create_hs_request(_error, _exporter), do: nil

  defp webhook_result([]), do: :ok

  defp webhook_result(exporters) do
    %{exporters: Enum.map(exporters, & &1.exporter_transigo_uid)}
    |> Helper.notify_api_users("daily_signing_check")
  end
end
