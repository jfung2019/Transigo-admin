defmodule TransigoAdminWeb.Api.Resolvers.Account do
  alias TransigoAdmin.Account

  def list_exporters(_root, args, _context), do: Account.list_exporters_paginated(args)

  def list_importers(_root, args, _context), do: Account.list_importers_paginated(args)
end
