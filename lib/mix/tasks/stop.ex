defmodule Mix.Tasks.Bootleg.Stop do
  use Bootleg.MixTask, :stop

  @shortdoc "Stops a deployed release."

  @moduledoc """
  Stops a deployed release using systemd.

  # Usage:

    * mix bootleg.stop

  """
end
