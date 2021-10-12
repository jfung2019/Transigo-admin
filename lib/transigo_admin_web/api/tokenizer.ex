defmodule TransigoAdminWeb.Tokenizer do
  @salt "encrypt salt"

  @spec encrypt(any()) :: binary()
  @doc """
  Encrypts data for tokenization.
  """
  def encrypt(data), do: Phoenix.Token.sign(TransigoAdminWeb.Endpoint, @salt, data)

  @spec decrypt(binary()) :: {:ok, any()} | {:error, :expired} | {:error, :invalid}
  def decrypt(data), do: Phoenix.Token.verify(TransigoAdminWeb.Endpoint, @salt, data)
end
