defmodule Mix.Tasks.Bootleg.Build do
  use Mix.Task

  @shortdoc "Build a release"

  @moduledoc """
  Build a release

  # Usage:

    * mix bootleg.build [Options]

  ## Build Commands:

    * mix bootleg.build release [--revision=<git-revision>|--tag=<git-tag>] [--branch=<git-branch>] [Options]

  """

  @spec run(OptionParser.argv) :: :ok
  def run(args) do

    mix_env = Application.get_env(:bootleg, :mix_env, "prod")
    version = Mix.Project.config[:version]

    config= Application.get_all_env(:bootleg)
#  authorize_hosts
    # Bootleg.Strategies.Build.RemoteSSH.ssh_connect(build_host, build_user)
    Bootleg.Strategies.Build.RemoteSSH.init(config)
    |> Bootleg.Strategies.Build.RemoteSSH.build(config, version)

    # |> Bootleg.Strategies.Build.RemoteSSH.git_push(user_host)
    # |> Bootleg.Strategies.Build.RemoteSSH.git_reset_remote(build_at, revision)
    # |> Bootleg.Strategies.Build.RemoteSSH.git_clean_remote(build_at)
    # |> Bootleg.Strategies.Build.RemoteSSH.get_and_update_deps(build_at, app, target_mix_env)
    # |> Bootleg.Strategies.Build.RemoteSSH.clean_compile(build_at, app, target_mix_env)
    # |> Bootleg.Strategies.Build.RemoteSSH.generate_release(build_at, app, target_mix_env)
    # |> copy_release_to_release_store
  end

end