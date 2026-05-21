defmodule Mix.Tasks.Bootleg.Ping do
  use Bootleg.MixTask, :ping

  @shortdoc "Pings an app."

  @moduledoc """
  Pings a deployed release.

  # Usage:

    * mix bootleg.ping

  """
end
