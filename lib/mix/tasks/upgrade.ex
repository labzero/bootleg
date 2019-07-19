defmodule Mix.Tasks.Bootleg.Upgrade do
  use Bootleg.MixTask, :upgrade

  @shortdoc "Build, deploy, and hot upgrade a release all in one command."

  @moduledoc """
  Build, deploy, and hot upgrade a release all in one command.

  Note that this comand will not do an Ecto migration.

  # Usage:

    * mix bootleg.upgrade
  """
end
