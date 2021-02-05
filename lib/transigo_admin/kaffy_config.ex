defmodule TransigoAdmin.KaffyConfig do
  def create_resources(_conn) do
    [
      account: [
        resources: [
          exporter: [
            schema: TransigoAdmin.Account.Exporter,
            admin: TransigoAdmin.Account.ExporterAdmin
          ],
          importer: [
            schema: TransigoAdmin.Account.Importer,
            admin: TransigoAdmin.Account.ImporterAdmin
          ]
        ]
      ],
      credit: [
        resources: [
          quota: [
            schema: TransigoAdmin.Credit.Quota,
            admin: TransigoAdmin.Credit.QuotaAdmin
          ],
          transaction: [
            schema: TransigoAdmin.Credit.Transaction,
            admin: TransigoAdmin.Credit.TransactionAdmin
          ],
          offer: [
            schema: TransigoAdmin.Credit.Offer,
            admin: TransigoAdmin.Credit.OfferAdmin
          ]
        ]
      ]
    ]
  end
end
