defmodule Bootleg.Strategies.Build.Distillery do
  @moduledoc false

  use Bootleg.Config
  alias Bootleg.{Git, UI, SSH, Config}

  def init do

    conn = SSH.init(:build)
    SSH.run!(conn, "git init")
    SSH.run!(conn, "git config receive.denyCurrentBranch ignore")
    conn
  end

  def build do
    conn = init()

    mix_env = config({:mix_env, "prod"})
    refspec = config({:refspec, "master"})
    invoke :clean
    :ok = git_push(conn, refspec)
    git_reset_remote(conn, refspec)
    git_clean_remote(conn)
    # get_and_update_deps(conn, mix_env)
    invoke :compile
    invoke :generate_release
    download_release_archive(conn, mix_env)
  end

  defp git_push(conn, refspec) do
    build_role = Config.get_role(:build)

    build_host =
      build_role.hosts
      |> List.first()
      |> SSH.ssh_host_options()

    options = Keyword.merge(build_host.options, build_role.options)

    user_host = "#{build_role.user}@#{build_host.name}"
    port = options[:port]
    user_host_port = if port do
      "#{user_host}:#{port}"
    else
      user_host
    end
    workspace = options[:workspace]
    host_url = case Path.type(workspace) do
      :absolute -> "ssh://#{user_host_port}#{workspace}"
      _         -> "ssh://#{user_host_port}/~/#{workspace}"
    end

    push_options = config({:push_options, "-f"})
    git_env = git_env(options)

    UI.info "Pushing new commits with git to: #{user_host_port}"

    case Git.push(["--tags", push_options, host_url, refspec], env: (git_env || [])) do
      {"", 0} -> :ok
      {result, 0} ->
        UI.puts_recv conn, result
        :ok
      {result, status} ->
        UI.puts_recv conn, result
        {:error, status}
    end

  end

  defp git_env(options) do
    git_ssh_options =
      options
      |> Enum.map(fn {key, value} ->
          case key do
            :identity -> "-i '#{value}'"
            :silently_accept_hosts -> "-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null"
            _ -> nil
          end
        end)
      |> Enum.filter(fn v -> v end)

    if Enum.count(git_ssh_options) > 0 do
      [{"GIT_SSH_COMMAND", "ssh #{Enum.join(git_ssh_options, " ")}"}]
    end
  end

  defp git_reset_remote(ssh, refspec) do
    UI.info "Resetting remote hosts to refspec \"#{refspec}\""
    ssh
    |> SSH.run!("git reset --hard #{refspec}")
    |> UI.puts_recv()
  end

  defp git_clean_remote(ssh) do
    UI.info "Skipped cleaning generated files from last build"

    # case SSHEx.run conn,
    #   '
    #   if [[ "$SKIP_GIT_CLEAN" = "true" ]]; then
    #     status "Skipped cleaning generated files from last build"
    #   else
    #     GIT_CLEAN_PATHS=${GIT_CLEAN_PATHS:="."}
    #     status "Cleaning generated files from last build"
    #     __sync_remote "
    #       [ -f ~/.profile ] && source ~/.profile
    #       set -e
    #       cd $DELIVER_TO
    #       echo \"cleaning files in: $GIT_CLEAN_PATHS\"
    #       git clean -fdx $GIT_CLEAN_PATHS
    #     "
    #   fi
    #   '
    ssh
  end

  # defp get_and_update_deps(ssh, mix_env) do
  #   UI.info "Fetching / Updating dependencies"
  #   commands = [
  #     "mix local.rebar --force",
  #     "mix local.hex --force",
  #     "mix deps.get --only=prod"
  #   ]
  #   commands = Enum.map(commands, &(with_env_vars(mix_env, &1)))
  #   # clean fetch of dependencies on the remote build host
  #   SSH.run!(ssh, commands)
  # end

  defp with_env_vars(mix_env, cmd) do
    "MIX_ENV=#{mix_env} #{cmd}"
  end

  defp download_release_archive(conn, mix_env) do
    app_name = Config.app
    app_version = Config.version
    remote_path = "_build/#{mix_env}/rel/#{app_name}/releases/#{app_version}/#{app_name}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{app_version}.tar.gz")

    UI.info "Downloading release archive"
    File.mkdir_p!(local_archive_folder)

    SSH.download(conn, remote_path, local_path)
    {:ok, local_path}
  end
end
