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

    _mix_env = Application.get_env(:bootleg, :mix_env, "prod")
    version = Project.config[:version]
    config = Application.get_env(:bootleg, :build)
    strategy = config[:strategy] || Bootleg.Strategies.Build.RemoteSSH

    config
    |> strategy.init
    |> strategy.build(config, version)
  end

end
