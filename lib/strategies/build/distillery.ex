defmodule Bootleg.Strategies.Build.Distillery do

  @moduledoc ""

  @ssh Application.get_env(:bootleg, :ssh, Bootleg.SSH)
  @git Application.get_env(:bootleg, :git, Bootleg.Git)

  alias Bootleg.{Config, Config.BuildConfig, Project, UI}

  @config_keys ~w(host user workspace refspec)

  def init(%Config{build: %BuildConfig{} = build_config}, %Project{} = _project) do
    ssh_options = [
      identity: build_config.identity,
      workspace: build_config.workspace,
      create_workspace: true]

    with :ok <- Bootleg.check_config(build_config, @config_keys),
         conn <- @ssh.init(build_config.host, build_config.user, ssh_options) do
           @ssh.run!(conn, "git init")
           @ssh.run!(conn, "git config receive.denyCurrentBranch ignore")
           conn
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  def build(%Config{build: %BuildConfig{} = build_config} = config, %Project{} = project) do
    conn = init(config, project)

    mix_env = build_config.mix_env || "prod"

    :ok = git_push conn, build_config
    git_reset_remote(conn, build_config.refspec)
    git_clean_remote(conn)
    get_and_update_deps(conn, mix_env)
    clean_compile(conn, mix_env)
    generate_release(conn, mix_env)
    download_release_archive(conn, mix_env, project)
  end

  defp git_push(conn, %BuildConfig{user: user, host: host, workspace: workspace, push_options: push_options, refspec: refspec} = build_config) do
    user_host = "#{user}@#{host}"
    host_url = "#{user_host}:#{workspace}"
    git_env = if build_config.identity, do: [{"GIT_SSH_COMMAND", "ssh -i '#{build_config.identity}'"}]

    UI.info "Pushing new commits with git to: #{user_host}"

    case @git.push(["--tags", push_options, host_url, refspec], env: (git_env || [])) do
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
    |> @ssh.run!("git reset --hard #{refspec}")
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
    @ssh.run!(ssh, commands)
  end

  defp clean_compile(ssh, mix_env) do
    UI.info "Compiling remote build"
    commands = Enum.map(["mix deps.compile", "mix compile"], &(with_env_vars(mix_env, &1)))
    @ssh.run!(ssh, commands)
  end

  defp with_env_vars(mix_env, cmd) do
    "MIX_ENV=#{mix_env} #{cmd}"
  end

  defp generate_release(ssh, mix_env) do
    UI.info "Generating release"

    # build assets for phoenix apps
    @ssh.run!(ssh, "[ -f package.json ] && npm install")
    @ssh.run!(ssh, "[ -f brunch-config.js ] && [ -d node_modules ] && ./node_modules/brunch/bin/brunch b -p")
    @ssh.run!(ssh, "[ -d deps/phoenix ] && " <> with_env_vars(mix_env, "mix phoenix.digest"))

    @ssh.run!(ssh, with_env_vars(mix_env, "mix release"))
  end

  defp download_release_archive(conn, mix_env, %Project{} = project) do
    remote_path = "_build/#{mix_env}/rel/#{project.app_name}/releases/#{project.app_version}/#{project.app_name}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "build.tar.gz")

    UI.info "Downloading release archive"
    File.mkdir_p!(local_archive_folder)

    case @ssh.download(conn, remote_path, local_path) do
      :ok -> {:ok, local_path}
      _ -> raise "Error: downloading of release archive failed"
    end
  end
end
