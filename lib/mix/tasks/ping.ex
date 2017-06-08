defmodule Mix.Tasks.Bootleg.Ping do
  use Mix.Task

  @shortdoc "Pings an app."

  alias Bootleg.{Config, Config.ManageConfig}

  @moduledoc """
  Pings a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.ping

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config

    %Config{
      manage: %ManageConfig{strategy: manager}
    } = config

    config
    |> manager.init
    |> manager.ping(config)
    :ok
  end
end
