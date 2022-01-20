defmodule TransigoAdmin.Job.DailySigningCheck do
  @moduledoc """
  Generate new msa if the msa was not fully signed for more than 1 month
  """
  use Oban.Worker, queue: :default, max_attempts: 1

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
        result =
          DateTime.from_unix!(created_at, :second)
          |> Timex.diff(Timex.now(), :month)
          |> regenerate_msa(exporter)

        result

      _ ->
        nil
    end
  end

  def regenerate_msa(created_diff, %{contact: _c, marketplace: _m} = exporter) do
    cond do
      created_diff <= -1 ->
        {:ok, payload} = Account.get_msa_payload(exporter, exporter.cn_msa)

        payload
        |> @util_api.generate_exporter_msa()
        |> create_hs_request(exporter)

      true ->
        nil
    end
  end

  defp create_hs_request({:ok, msa_path}, exporter) do
    payload = [
      {"client_id", Application.get_env(:transigo_admin, :hs_client_id)},
      {"test_mode", "1"},
      {"use_text_tags", "1"},
      {"hide_text_tags", "1"},
      {:file, msa_path, {"form-data", [name: "file[0]", filename: Path.basename(msa_path)]}, []},
      {"signers[0][name]", "#{exporter.signatory_first_name} #{exporter.signatory_last_name}"},
      {"signers[0][email_address]", exporter.signatory_email},
      {"signers[1][name]", "Nir Tal"},
      {"signers[1][email_address]", "nir.tal@transigo.io"}
    ]

    case @hs_api.create_signature_request(payload) do
      {:ok, %{"signature_request" => %{"signature_request_id" => req_id}}} ->
        Account.update_exporter_hs_request(exporter, %{
          hellosign_signature_request_id: req_id,
          hs_signing_status: :awaiting_signature
        })

      _ ->
        nil
    end
  end

  defp create_hs_request(_error, _exporter), do: nil

  defp webhook_result([]), do: :ok

  defp webhook_result(exporters) do
    %{exporters: Enum.map(exporters, fn {:ok, exporter} -> exporter.exporter_transigo_uid end)}
    |> Helper.notify_api_users("daily_signing_check")
  end
end
