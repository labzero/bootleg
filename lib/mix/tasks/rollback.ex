defmodule Mix.Tasks.Bootleg.Rollback do
  use Bootleg.MixTask, :rollback

  @shortdoc "Roll back to the previous release"

  @moduledoc """
  Roll back to the previous release

  # Usage:

    * mix bootleg.rollback

  """
end
