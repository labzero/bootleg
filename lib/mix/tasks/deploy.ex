defmodule Mix.Tasks.Bootleg.Deploy do
  use Mix.Task

  @shortdoc "Deploy a release from the local cache"

  @moduledoc """
  Deploy a release

  # Usage:

    * mix bootleg.deploy [cluster] [release] [Options]

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    use Bootleg.Config
    invoke :deploy
  end
end
