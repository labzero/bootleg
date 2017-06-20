defmodule Mix.Tasks.Bootleg.Build do
  use Mix.Task

  alias Bootleg.Config
  import Bootleg.Strategies.Build.Distillery

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
    config = Bootleg.config()

    archiver = Config.strategy(config, :archive)
    project = Bootleg.project()

    {:ok, build_filename} = build(project)

    unless archiver == false do
      archiver.archive(project, build_filename)
    end
  end

end
