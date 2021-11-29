defmodule TransigoAdmin.ServiceManager.Util.UtilApi do
  @behaviour TransigoAdmin.ServiceManager.Util.UtilBehavior

  import Ecto.Query

  alias TransigoAdmin.Repo

  def create_importer(importer_param) do
    payload =
      importer_param
      |> format_date()
      |> Jason.encode!()

    {:ok, user_id} = Ecto.UUID.dump(Application.get_env(:transigo_admin, :dev_user_id))

    access_token =
      from(t in "tokens",
        where: t.user_id == ^user_id,
        select: t.access_token
      )
      |> Repo.one()

    HTTPoison.post("#{Application.get_env(:transigo_admin, :api_domain)}/v2/importers", payload, [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{access_token}"}
    ])
  end

  # def generate_assignment_notice(payload) do
  #   HTTPoison.post(
  #     "#{Application.get_env(:transigo_admin, :doctools_url)}/generate_assignment_notice",
  #     {:multipart, payload},
  #     []
  #   )
  #   |> save_file()
  # end

  def generate_assignment_notice(payload) do
    Tesla.post(
      "#{Application.get_env(:transigo_admin, :doctools_url)}/generate_assignment_notice",
      payload
    )
    |> save_file_tesla()
  end

  # def generate_exporter_msa(payload) do
  #   HTTPoison.post(
  #     "#{Application.get_env(:transigo_admin, :doctools_url)}/generate_msa",
  #     {:multipart, payload},
  #     [],
  #     recv_timeout: 60_000
  #   )
  #   |> save_file()
  # end

  def generate_exporter_msa(payload) do
    Tesla.post(
      "#{Application.get_env(:transigo_admin, :doctools_url)}/generate_msa",
      payload
    )
    |> save_file_tesla()
  end

  # def generate_transaction_doc(payload) do
  #   HTTPoison.post(
  #     "#{Application.get_env(:transigo_admin, :doctools_url)}/generate_trans_docs",
  #     {:multipart, payload},
  #     [],
  #     recv_timeout: 60_000
  #   )
  #   |> save_file()
  # end

  def generate_transaction_doc(payload) do
    Tesla.post(
      "#{Application.get_env(:transigo_admin, :doctools_url)}/generate_trans_docs",
      payload
    )
    |> save_file_tesla()
  end

  defp format_date(
         %{
           "incorporationDate" => %{
             "day" => incorp_day,
             "month" => incorp_month,
             "year" => incorp_year
           },
           "dateOfBirth" => %{"day" => dob_day, "month" => dob_month, "year" => dob_year}
         } = input
       ) do
    input
    |> Map.put("incorporationDate", "#{incorp_year}-#{incorp_month}-#{incorp_day}")
    |> Map.put("dateOfBirth", "#{dob_year}-#{dob_month}-#{dob_day}")
  end

  defp format_date(map), do: map

  # defp save_file(response) do
  #   case response do
  #     {:ok, %{status_code: 200, body: pdf_content}} ->
  #       with {:ok, temp} <- Briefly.create(extname: ".pdf"),
  #            :ok <- File.write(temp, pdf_content) do
  #         {:ok, temp}
  #       else
  #         error ->
  #           IO.inspect(error)
  #           {:error, "Fail to save file"}
  #       end

  #     error ->
  #       IO.inspect(error)
  #       {:error, error}
  #   end
  # end

  defp save_file_tesla(response) do
    case response do
      {:ok, %{status: 200, body: pdf_content}} ->
        with {:ok, temp} <- Briefly.create(extname: ".pdf"),
             :ok <- File.write(temp, pdf_content) do
          {:ok, temp}
        else
          error ->
            IO.inspect(error)
            {:error, "Fail to save file"}
        end

      error ->
        IO.inspect(error)
        {:error, error}
    end
  end
end
