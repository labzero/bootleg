defmodule Mix.Tasks.Bootleg.Build do
  use Mix.Task

  @shortdoc "Build a release"

  alias Bootleg.Config
  alias Bootleg.BuildConfig
  alias Bootleg.ArchiveConfig

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

    %Config{
      build: %BuildConfig{strategy: builder},
      archive: %ArchiveConfig{strategy: archiver}
    } = config

    {:ok, build_filename} = 
      config
      |> builder.init()
      |> builder.build(config)

    # build_filename = "bttn-0.0.1.tar.gz"
    unless archiver == false do
      archiver.archive(config, build_filename)
    end
  end

end
