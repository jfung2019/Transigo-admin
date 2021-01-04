defmodule TransigoAdmin.KaffyConfig do
  def create_resources(_conn) do
    [
      account: [
        name: "Account",
        resources: [
          exporter: [
            schema: TransigoAdmin.Account.Exporter,
            admin: TransigoAdmin.Account.ExporterAdmin
          ],
          importer: [
            schema: TransigoAdmin.Account.Importer,
            admin: TransigoAdmin.Account.ImporterAdmin,
          ]
        ]
      ],
      credit: [
        name: "Credit",
        resources: [
          quota: [
            schema: TransigoAdmin.Credit.Quota,
            admin: TransigoAdmin.Credit.QuotaAdmin
          ]
        ]
      ]
    ]
  end
end