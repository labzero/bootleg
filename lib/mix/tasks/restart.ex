defmodule Mix.Tasks.Bootleg.Restart do
  use Bootleg.MixTask, :restart

  @shortdoc "Restarts a deployed release."

  @moduledoc """
  Restarts a deployed release.

  # Usage:

    * mix bootleg.start

  """
end
