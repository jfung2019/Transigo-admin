defmodule GoogleMapsStub do
  def geocode("not an address"), do: {:error, ""}
  def geocode(_address), do: {:ok, ""}
end
