defmodule Mix.Tasks.Bootleg.Stop do
  use Mix.Task

  @shortdoc "Stops a deployed release."

  @moduledoc """
  Stops a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.stop

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    use Bootleg.Config
    invoke :stop
  end
end
