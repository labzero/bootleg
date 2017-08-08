defmodule Mix.Tasks.Bootleg.Update do
  use Bootleg.MixTask, :update

  @shortdoc "Build, deploy, and start a release all in one command."

  @moduledoc """
  Update a release.

  Note that this will stop any running nodes and then perform a cold start. The stop is performed with
  the task `stop_silent`, which differs from `stop` in that it does not require a node to already be
  running.

  # Usage:

    * mix bootleg.update
  """

end
