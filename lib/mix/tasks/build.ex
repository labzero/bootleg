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

    build_host = Application.get_env(:bootleg, :build_host)
    IO.puts "BUILD_HOST: #{build_host}"
    build_at = Application.get_env(:bootleg, :build_at)
    revision = Application.get_env(:bootleg, :revision, "HEAD")
    build_user  = Application.get_env(:bootleg, :build_user )
    user_host = "#{build_user}@#{build_host}"
    app = Application.get_env(:bootleg, :app)
    target_mix_env = Application.get_env(:bootleg, :mix_env, "prod")
    version = Mix.Project.config[:version]

#  authorize_hosts
    Bootleg.Strategies.Build.RemoteSSH.ssh_connect(build_host, build_user)
    |> Bootleg.Strategies.Build.RemoteSSH.init_app_remotely(build_host, build_user, build_at)
    |> Bootleg.Strategies.Build.RemoteSSH.git_push(user_host)
    |> Bootleg.Strategies.Build.RemoteSSH.git_reset_remote(build_at, revision)
    |> Bootleg.Strategies.Build.RemoteSSH.git_clean_remote(build_at)
    |> Bootleg.Strategies.Build.RemoteSSH.get_and_update_deps(build_at, app, target_mix_env)
    |> Bootleg.Strategies.Build.RemoteSSH.clean_compile(build_at, app, target_mix_env)
    |> Bootleg.Strategies.Build.RemoteSSH.generate_release(build_at, app, target_mix_env)
    # |> copy_release_to_release_store
  end

end