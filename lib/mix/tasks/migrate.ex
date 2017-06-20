defmodule Mix.Tasks.Bootleg.Migrate do
  use Mix.Task

  alias Bootleg.Config

  @shortdoc "Invokes a releases migrations."

  @moduledoc """
  Invokes the migrations for a release by invoking a user-defined module and function in the
  release via RPC.

  # Usage:

    * mix bootleg.migrate

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config()

    strategy = Config.strategy(config, :manage)
    project = Bootleg.project()

    config
    |> strategy.init(project)
    |> strategy.migrate(config, project)
    :ok
  end
end
