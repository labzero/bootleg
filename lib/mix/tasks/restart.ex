defmodule Mix.Tasks.Bootleg.Restart do
  use Bootleg.MixTask, :restart

  @shortdoc "Restarts a deployed release."

  @moduledoc """
  Restarts a deployed release using systemctl.

  # Usage:

    * mix bootleg.restart

  """
end
