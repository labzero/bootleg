defmodule Mix.Tasks.Bootleg do
  use Bootleg.Task

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

end
