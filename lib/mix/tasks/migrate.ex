defmodule Mix.Tasks.Bootleg.Migrate do
  use Mix.Task

  @shortdoc "Invokes a releases migrations."

  @moduledoc """
  Invokes the migrations for a release by invoking a user-defined module and function in the
  release via RPC.

  # Usage:

    * mix bootleg.migrate

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    config = Bootleg.config
    strategy = Map.get(config.manage, :strategy) || Bootleg.Strategies.Manage.Distillery
    config
    |> strategy.init
    |> strategy.migrate(config)
    :ok
  end
end
