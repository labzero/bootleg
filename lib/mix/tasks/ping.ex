defmodule Mix.Tasks.Bootleg.Ping do
  use Mix.Task

  alias Bootleg.Config

  @shortdoc "Pings an app."

  @moduledoc """
  Pings a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.ping

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config()

    strategy = Config.strategy(config, :manage)
    project = Bootleg.project()

    config
    |> strategy.init(project)
    |> strategy.ping(config, project)
    :ok
  end
end
