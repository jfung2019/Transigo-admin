defmodule TransigoAdmin.ServiceManager.HelloSign.HsMock do
  @behaviour TransigoAdmin.ServiceManager.HelloSign.HsBehavior

  def get_signature_request(_request_id),
    do: {:ok, %{"signature_request" => %{"signatures" => []}}}

  def get_sign_url(_signature_id), do: {:ok, %{"embedded" => %{"sign_url" => "http://heelosign"}}}
end