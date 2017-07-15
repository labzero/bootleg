defmodule Mix.Tasks.Bootleg.Stop do
  use Bootleg.Task, :stop

  @shortdoc "Stops a deployed release."

  @moduledoc """
  Stops a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.stop

  """
end
