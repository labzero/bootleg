defmodule Mix.Tasks.Bootleg.Restart do
  use Mix.Task

  @shortdoc "Restarts a deployed release."

  alias Bootleg.Config

  @moduledoc """
  Restarts a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.start

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config

    %Config{
      manage: %Config.ManageConfig{strategy: manager}
    } = config

    config
    |> manager.init
    |> manager.restart(config)
    :ok
  end
end
