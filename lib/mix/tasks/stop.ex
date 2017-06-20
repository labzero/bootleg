defmodule Mix.Tasks.Bootleg.Stop do
  use Mix.Task

  alias Bootleg.Config

  @shortdoc "Stops a deployed release."

  @moduledoc """
  Stops a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.stop

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config()

    strategy = Config.strategy(config, :manage)
    project = Bootleg.project()

    config
    |> strategy.init(project)
    |> strategy.stop(config, project)
    :ok
  end
end
