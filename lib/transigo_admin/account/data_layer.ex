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

  @mac_const "1c44ee86f9d661aecceacb41351dd6135d46721cd3221ed90d5ffe67276936c5"

  def shakdf(uuid, salt \\ @mac_const, n \\ 64) do
    if n == 0 do
      sha3(uuid <> Base.decode16!(salt |> String.upcase()))
    else
      Enum.reduce(0..n, sha3(uuid <> Base.decode16!(salt |> String.upcase())), fn _elem, acc ->
        sha3(acc)
      end)
    end
  end

  defp sha3(input) do
    :crypto.hash(:sha3_256, input)
  end

  def generate_uid(code) when code in @valid_codes do
    rand =
      HexGen.generate()
      |> String.graphemes()
      |> Enum.chunk_every(4)
      |> Enum.join("-")

    uuid = "T#{code}-#{rand}"
    mac = generate_hash(uuid)

    "#{uuid}-#{mac}"
  end

  def generate_uid(_), do: {:error, "invalid code"}

  defp generate_hash(uuid) do
    hash =
      shakdf(uuid, @mac_const, 0)
      |> Base.encode16()
      |> String.downcase()

    "#{String.slice(hash, 0, 4)}-#{String.slice(hash, 4, 4)}"
  end

  def check_uid(uid, code) do
    with ^code <- String.slice(uid, 1, 3),
         true <- String.slice(uid, 0, 24) |> generate_hash() == String.slice(uid, -9..-1) do
      true
    else
      _ -> false
    end
  end
end

defmodule(HexGen, do: use(Puid, bits: 64, charset: :hex))
