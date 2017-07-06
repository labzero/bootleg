defmodule Mix.Tasks.Bootleg.Ping do
  use Mix.Task

  @shortdoc "Pings an app."

  @moduledoc """
  Pings a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.ping

  """
  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    use Bootleg.Config
    invoke :ping
  end
end
