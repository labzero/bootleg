defmodule Mix.Tasks.Bootleg.DeployUpgrade do
  use Bootleg.MixTask, :deploy_upgrade

  @shortdoc "Deploy an upgrade release"

  @moduledoc """
  Deploy an upgrade release

  ## Usage

      mix bootleg.deploy_upgrade

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
