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
    use Bootleg.Config
    invoke :migrate
  end
end
