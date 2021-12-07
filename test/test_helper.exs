ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(TransigoAdmin.Repo, :manual)

Mox.defmock(TransigoAdmin.Job.HelperMock, for: TransigoAdmin.Job.Helper_API)

Application.put_env(:transigo_admin, :helper, TransigoAdmin.Job.HelperMock)
