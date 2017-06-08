defmodule Mix.Tasks.Bootleg.Stop do
  use Mix.Task

  @shortdoc "Stops a deployed release."

  alias Bootleg.{Config, Config.ManageConfig}

  @moduledoc """
  Stops a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.stop

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config

    %Config{
      manage: %ManageConfig{strategy: manager}
    } = config

    config
    |> manager.init
    |> manager.stop(config)
    :ok
  end
end
