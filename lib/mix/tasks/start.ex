defmodule Mix.Tasks.Bootleg.Start do
  use Mix.Task

  @shortdoc "Starts a deployed release."

  alias Bootleg.{Config, ManageConfig}

  @moduledoc """
  Starts a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.start

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config

    %Config{
      manage: %ManageConfig{strategy: manager}
    } = config

    config
    |> manager.init
    |> manager.start(config)
    :ok
  end
end
