defmodule TransigoAdminWeb.ApiErrorView do
  use TransigoAdminWeb, :view

  def render("errors.json", %{message: message}) do
    if is_list(message) do
      %{errors: message}
    else
      %{errors: [message]}
    end
  end
end
