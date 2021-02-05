defmodule TransigoAdmin.Job.ObanLogger do
  require Logger

  def handle_event([:oban, :failed], measure, meta, _) do
    {blamed, stack} = Exception.blame(meta.kind, meta.error, meta.stack)
    formatted = Exception.format(meta.kind, blamed, stack)
    Logger.error("[Oban] #{meta.worker} failed in #{measure.duration} with: \n\n #{formatted}")
  end

  def handle_event([:oban, :started], measure, meta, _) do
    Logger.warn("[Oban] :started #{meta.worker} at #{measure.system_time}")
  end

  def handle_event([:oban, event], measure, meta, _) do
    Logger.warn("[Oban] #{event} #{meta.worker} ran in #{measure.duration}")
  end
end
