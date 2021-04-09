defmodule TransigoAdminWeb.Api.Types.Helpers do
  use Absinthe.Schema.Notation

  scalar :date do
    parse(fn input ->
      case Timex.parse(input.value, "{ISO:Extended}") do
        {:ok, iso_date} ->
          {:ok, date} = DateTime.from_naive(iso_date, "Etc/UTC")
          {:ok, date}

        _ ->
          :error
      end
    end)

    serialize(fn
      %DateTime{} = date ->
        DateTime.to_iso8601(date)

      date ->
        Date.to_iso8601(date)
    end)
  end
end
