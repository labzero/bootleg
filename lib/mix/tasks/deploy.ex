defmodule Mix.Tasks.Bootleg.Deploy do
  use Mix.Task
  import Bootleg.Strategies.Deploy.Distillery

  @shortdoc "Deploy a release from the local cache"

  @moduledoc """
  Deploy a release

  # Usage:

    * mix bootleg.deploy [cluster] [release] [Options]

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    deploy(Bootleg.project())
  end
end
