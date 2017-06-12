defmodule Mix.Tasks.Bootleg.Restart do
  use Mix.Task

  alias Bootleg.Config

  @shortdoc "Restarts a deployed release."

  @moduledoc """
  Restarts a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.start

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config()

    strategy = Config.strategy(config, :manage)
    project = Bootleg.project()

    config
    |> strategy.init(project)
    |> strategy.restart(config, project)
    :ok
  end
end
