defmodule TransigoAdminWeb.ImporterFormController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account

  @util_api Application.compile_env(:transigo_admin, :util_api)

  plug :assign_available_options, only: [:new]

  def new(conn, _param), do: render(assign(conn, :importer_form, %{}), "new.html")

  def create(conn, %{"importer_form" => importer_param}) do
    case @util_api.create_importer(importer_param) do
      {:ok, %{body: body}} ->
        message = Jason.decode!(body)
        IO.inspect(message)
        render(conn, "new.html")

      {:error, _error} ->
        conn
        |> assign_available_options(nil)
        |> render("new.html")
    end
  end

  defp assign_available_options(conn, _opt) do
    conn
    |> assign(:available_business_types, Account.importer_business_types())
    |> assign(:available_business_classifications, Account.importer_business_classifications())
    |> assign(:available_states, Account.address_states())
  end
end
