defmodule Mix.Tasks.Bootleg.BuildUpgrade do
  use Bootleg.MixTask, :build_upgrade

  @shortdoc "Build a release for upgrade"

  @moduledoc """
  Build a release for upgrade

  ## Usage

      mix bootleg.build

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
