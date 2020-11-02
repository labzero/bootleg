defmodule Mix.Tasks.Bootleg.HotDowngrade do
  use Bootleg.MixTask, :hot_downgrade

  @shortdoc "Downgrade a running release with the last release"

  @moduledoc """
  Downgrade a running release with the last release

  ## Usage

      mix bootleg.hot_downgrade

  ## Caution

  Please never try to hot upgrade a running application without 
  having first a good understand of how a hot upgrade is performed, 
  its limitations and steps required.

  ## Documentation

  Please see the "Hot upgrading a running application" section 
  of `bootleg.upgrade` documentation for an overview of 
  the hot upgrade process:

      mix help bootleg.upgrade
  """
end
