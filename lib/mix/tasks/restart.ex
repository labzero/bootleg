defmodule Mix.Tasks.Bootleg.Restart do
  use Mix.Task

  @shortdoc "Restarts a deployed release."

  @moduledoc """
  Restarts a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.start

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config
    strategy = Map.get(config, :strategy) || Bootleg.Strategies.Administration.RemoteSSH
    config
    |> strategy.init
    |> strategy.restart(config)
    :ok
  end
end
