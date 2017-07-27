defmodule Mix.Tasks.Bootleg.Start do
  use Bootleg.MixTask, :start

  @shortdoc "Starts a deployed release."

  @moduledoc """
  Starts a deployed release using the `Distillery` helper.

  # Usage:

    * mix bootleg.start

  """
end
