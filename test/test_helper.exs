ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(TransigoAdmin.Repo, :manual)

Mox.defmock(TransigoAdmin.Job.HelperMock, for: TransigoAdmin.Job.HelperApi)

Application.put_env(:transigo_admin, TransigoAdmin.Job.HelperApi,
  adapter: TransigoAdmin.Job.HelperMock
)
