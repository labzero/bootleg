defmodule Mix.Tasks.Bootleg.Restart do
  use Bootleg.MixTask, :restart

  @shortdoc "Restarts a deployed release."

  @moduledoc """
  Restarts a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.start

  """
end
