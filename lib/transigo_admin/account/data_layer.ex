defmodule TransigoAdmin.DataLayer do
  @valid_codes [
    "imp",
    "exp",
    "con",
    "usr",
    "cre",
    "ofr",
    "tra",
    "doc",
    "quo",
    "tok",
    "usp",
    "mes"
  ]

  def generate_uid(code) when code in @valid_codes do
    rand =
      HexGen.generate()
      |> String.to_charlist()
      |> Enum.chunk_every(4)
      |> Enum.map(fn x ->
        to_string(x)
      end)
      |> Enum.join("-")

    uuid = "T#{code}-#{rand}"
    mac = generate_hash(uuid)

    "#{uuid}-#{mac}"
  end

  def generate_uid(_), do: {:error, "invalid code"}

  defp generate_hash(uuid) do
    :crypto.hash(:sha256, uuid)
    |> Base.encode16()
    |> String.downcase()
  end


  def check_uid(uid, code) do
    with ^code <- String.slice(uid, 1, 3),
         true <- String.slice(uid, 0, 24) |> generate_hash() == String.slice(uid, -64..-1) do
           true
         else
          _ -> false
         end
  end
end

defmodule(HexGen, do: use(Puid, bits: 64, charset: :hex))
