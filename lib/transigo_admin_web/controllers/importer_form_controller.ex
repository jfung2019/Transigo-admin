defmodule TransigoAdminWeb.ImporterFormController do
  use TransigoAdminWeb, :controller

  alias TransigoAdmin.Account

  @util_api Application.compile_env(:transigo_admin, :util_api)

  plug :assign_available_options, only: [:new]

  def new(conn, _param), do: render(assign(conn, :importer_form, %{}), "new.html")

  def create(conn, %{"importer_form" => importer_param}) do
    case @util_api.create_importer(importer_param) do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => %{"importer_transigoUID" => importer_uid}}} ->
            conn
            |> put_flash(:info, "Signed up successfully! Your importer id is #{importer_uid}")
            |> assign_available_options(nil)
            |> render("new.html")

          {:ok, %{"errors" => errors}} ->
            conn
            |> assign_errors(errors)
            |> assign_available_options(nil)
            |> render("new.html")

          _ ->
            conn
            |> assign_errors([])
            |> assign_available_options(nil)
            |> render("new.html")
        end

      _ ->
        conn
        |> assign_errors([])
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

  defp assign_errors(conn, errors) do
    cond do
      is_map(Enum.at(errors, 0)) ->
        error_fields =
          errors
          |> Enum.map(fn %{"args" => args} -> Map.keys(args) |> Enum.at(0) end)
          |> Enum.join(", ")

        put_flash(conn, :error, "#{error_fields} has incorrect format.")

      is_binary(Enum.at(errors, 0)) ->
        put_flash(conn, :error, "Error found: #{Enum.join(errors, ", ")}")

      true ->
        put_flash(conn, :error, "Failed to sign up")
    end
  end
end
