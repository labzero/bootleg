defmodule Mix.Tasks.Bootleg.Deploy do
  use Mix.Task

  @shortdoc "Deploy a release from the local cache"

  alias Bootleg.{Config, Config.DeployConfig}

  @moduledoc """
  Deploy a release

  # Usage:

    * mix bootleg.deploy [cluster] [release] [Options]

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config

    %Config{
      deploy: %DeployConfig{strategy: deployer}
    } = config

    config
    |> deployer.deploy()
  end
end
