defmodule TransigoAdmin.ServiceManager.HelloSign.HsMock do
  @behaviour TransigoAdmin.ServiceManager.HelloSign.HsBehavior

  def get_signature_request(_request_id),
    do: {:ok, %{"signature_request" => %{"signatures" => []}}}

  def get_sign_url(_signature_id), do: {:ok, %{"embedded" => %{"sign_url" => "http://heelosign"}}}

  def create_signature_request([]), do: {:ok, %{}}

  def fetch_sign_url(_sign_id), do: ""

  def get_signature_file_url(_sign_request_id), do: {:ok, ""}
end
