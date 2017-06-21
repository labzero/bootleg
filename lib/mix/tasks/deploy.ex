defmodule Mix.Tasks.Bootleg.Deploy do
  use Mix.Task

  alias Bootleg.Config

  @shortdoc "Deploy a release from the local cache"

  @moduledoc """
  Deploy a release

  # Usage:

    * mix bootleg.deploy [cluster] [release] [Options]

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config()

    strategy = Config.strategy(config, :deploy)
    project = Bootleg.project()

    config
    |> strategy.deploy(project)
  end
end
