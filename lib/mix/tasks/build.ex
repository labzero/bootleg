defmodule Mix.Tasks.Bootleg.Build do
  use Mix.Task

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

    _mix_env = Application.get_env(:bootleg, :mix_env, "prod")
    version = Mix.Project.config[:version]

    config = Application.get_env(:bootleg, :build)
    strategy = config[:strategy]
    strategy.init(config)
    |> strategy.build(config, version)
  end

end