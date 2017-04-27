defmodule Mix.Tasks.Bootleg.Build do
  use Mix.Task

  alias Mix.Project

  @shortdoc "Build a release"

  @moduledoc """
  Build a release

  # Usage:

    * mix bootleg.build [Options]

  ## Build Commands:

    * mix bootleg.build release [--revision=<git-revision>|--tag=<git-tag>] [--branch=<git-branch>] [Options]

  """

  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config
    strategy = Map.get(config, :strategy) || Bootleg.Strategies.Build.RemoteSSH
    strategy.build(config)
  end

end
