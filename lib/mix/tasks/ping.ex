defmodule Mix.Tasks.Bootleg.Ping do
  use Bootleg.MixTask, :ping

  @shortdoc "Pings an app."

  @moduledoc """
  Pings a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.ping

  """
end
