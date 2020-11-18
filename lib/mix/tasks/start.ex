defmodule Mix.Tasks.Bootleg.Start do
  use Bootleg.MixTask, :start

  @shortdoc "Starts a deployed release."

  @moduledoc """
  Starts a deployed release using systemctl.

  # Usage:

    * mix bootleg.start

  """
end
