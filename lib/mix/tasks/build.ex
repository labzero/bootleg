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
    config = Application.get_env(:bootleg, :build)
    builder = config[:build_strategy] || Bootleg.Strategies.Build.RemoteSSH
    archiver = config[:archive_strategy] || Bootleg.Strategies.Archive.LocalDirectory

    build = 
      config
      |> builder.init()
      |> builder.build(config)

    archive =
      config
      |> archiver.init()
      |> archiver.archive(build)
  end

end
