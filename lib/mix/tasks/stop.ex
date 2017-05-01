defmodule Mix.Tasks.Bootleg.Stop do
  use Mix.Task

  @shortdoc "Stops a deployed release."

  @moduledoc """
  Stops a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.stop

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config
    strategy = Map.get(config, :strategy) || Bootleg.Strategies.Administration.RemoteSSH
    config
    |> strategy.init
    |> strategy.stop(config)
    :ok
  end
end
