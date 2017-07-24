defmodule Mix.Tasks.Bootleg.Deploy do
  use Bootleg.MixTask, :deploy

  @shortdoc "Deploy a release from the local cache"

  @moduledoc """
  Deploy a release

  # Usage:

    * mix bootleg.deploy

  """
end
