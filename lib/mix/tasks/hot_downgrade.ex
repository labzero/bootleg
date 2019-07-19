defmodule Mix.Tasks.Bootleg.HotDowngrade do
  use Bootleg.MixTask, :hot_downgrade

  @shortdoc "Downgrade a running release with the last release"

  @moduledoc """
  Downgrade a running release with the last release

  # Usage:

    * mix bootleg.hot_downgrade

  """
end
