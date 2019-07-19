defmodule Mix.Tasks.Bootleg.HotUpgrade do
  use Bootleg.MixTask, :hot_upgrade

  @shortdoc "Upgrade a running release with the last release"

  @moduledoc """
  Upgrade a running release with the last release

  # Usage:

    * mix bootleg.hot_upgrade

  """
end
