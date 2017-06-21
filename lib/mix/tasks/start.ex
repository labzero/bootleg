defmodule Mix.Tasks.Bootleg.Start do
  use Mix.Task

  alias Bootleg.Config

  @shortdoc "Starts a deployed release."

  @moduledoc """
  Starts a deployed release using the `Distillery` helper.

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
    |> strategy.start(config, project)
    :ok
  end
end
