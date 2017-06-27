defmodule Bootleg.Strategies.Build.Distillery do

  @moduledoc ""

  alias Bootleg.{Git, Project, UI, SSH, Config}

  def init(%Project{} = _project) do

    conn = SSH.init(:build, create_workspace: true)
    SSH.run!(conn, "git init")
    SSH.run!(conn, "git config receive.denyCurrentBranch ignore")
    conn
  end

  def build(%Project{} = project) do
    conn = init(project)

    mix_env = Config.get_config(:mix_env, "prod")
    refspec = Config.get_config(:refspec, "master")

    :ok = git_push(conn, refspec)
    git_reset_remote(conn, refspec)
    git_clean_remote(conn)
    get_and_update_deps(conn, mix_env)
    clean_compile(conn, mix_env)
    generate_release(conn, mix_env)
    download_release_archive(conn, mix_env, project)
  end

  defp git_push(conn, refspec) do
    build_role = Config.get_role(:build)
    user_host = "#{build_role.user}@#{List.first(build_role.hosts)}"
    host_url = "#{user_host}:#{build_role.options[:workspace]}"
    push_options = Config.get_config(:push_options, "-f")
    identity = build_role.options[:identity]
    git_env = if identity, do: [{"GIT_SSH_COMMAND", "ssh -i '#{identity}'"}]

    UI.info "Pushing new commits with git to: #{user_host}"

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

  defp get_and_update_deps(ssh, mix_env) do
    UI.info "Fetching / Updating dependencies"
    commands = [
      "mix local.rebar --force",
      "mix local.hex --force",
      "mix deps.get --only=prod"
    ]
    commands = Enum.map(commands, &(with_env_vars(mix_env, &1)))
    # clean fetch of dependencies on the remote build host
    SSH.run!(ssh, commands)
  end

  defp clean_compile(ssh, mix_env) do
    UI.info "Compiling remote build"
    commands = Enum.map(["mix deps.compile", "mix compile"], &(with_env_vars(mix_env, &1)))
    SSH.run!(ssh, commands)
  end

  defp with_env_vars(mix_env, cmd) do
    "MIX_ENV=#{mix_env} #{cmd}"
  end

  defp generate_release(ssh, mix_env) do
    UI.info "Generating release"

    # build assets for phoenix apps
    SSH.run!(ssh, "[ -f package.json ] && npm install || true")
    SSH.run!(ssh, "[ -f brunch-config.js ] && [ -d node_modules ] && ./node_modules/brunch/bin/brunch b -p || true")
    SSH.run!(ssh, "[ -d deps/phoenix ] && " <> with_env_vars(mix_env, "mix phoenix.digest") <> " || true")

    SSH.run!(ssh, with_env_vars(mix_env, "mix release"))
  end

  defp download_release_archive(conn, mix_env, %Project{} = project) do
    remote_path = "_build/#{mix_env}/rel/#{project.app_name}/releases/#{project.app_version}/#{project.app_name}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "build.tar.gz")

    UI.info "Downloading release archive"
    File.mkdir_p!(local_archive_folder)

    SSH.download(conn, remote_path, local_path)
    {:ok, local_path}
  end
end
