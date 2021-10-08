defmodule GoogleMapsStub do
  def geocode(_address), do: {:ok, ""}
end
