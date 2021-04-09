defmodule TransigoAdminWeb.Api.Resolvers.Credit do
  alias TransigoAdmin.Credit

  def list_quotas(_root, args, _context), do: Credit.list_quotas_paginated(args)

  def list_offers(_root, args, _context), do: Credit.list_offers_paginated(args)
end
