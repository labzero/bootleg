defmodule Mix.Tasks.Bootleg.Ping do
  use Mix.Task

  @shortdoc "Pings an app."

  @moduledoc """
  Pings a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.ping

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config
    strategy = Map.get(config, :strategy) || Bootleg.Strategies.Administration.RemoteSSH
    config
    |> strategy.init
    |> strategy.ping(config)
    :ok
  end
end
