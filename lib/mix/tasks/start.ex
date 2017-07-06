defmodule Mix.Tasks.Bootleg.Start do
  use Mix.Task

  @shortdoc "Starts a deployed release."

  @moduledoc """
  Starts a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.start

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    use Bootleg.Config
    invoke :start
  end
end
