defmodule Mix.Tasks.Bootleg do
  use Mix.Task

  @shortdoc "Build and deploy releases"

  @moduledoc """
  Build and deploy Elixir applications

  # Usage:

    * mix bootleg <command> command-info [Options]
    * mix bootleg --help|--version
    * mix bootleg help <command>

  ## Build Commands:

    * mix bootleg build release [--refspec=<git-refspec>|--tag=<git-tag>] [--branch=<git-branch>] [Options]

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    :ok
  end

end
