defmodule Bootleg.Strategies.Build.Distillery do

  @moduledoc ""

  @ssh Application.get_env(:bootleg, :ssh) || Bootleg.SSH
  @git Application.get_env(:bootleg, :git) || Bootleg.Git

  alias Bootleg.{Config, BuildConfig, UI}

  @config_keys ~w(host user workspace revision)

  def init(%Config{build: %BuildConfig{identity: identity, workspace: workspace, host: host, user: user} = config}) do
    ssh_options = [identity: identity, workspace: workspace, create_workspace: true]
    with :ok <- Bootleg.check_config(config, @config_keys),
         conn <- @ssh.init(host, user, ssh_options) do
           @ssh.run!(conn, "git init")
           @ssh.run!(conn, "git config receive.denyCurrentBranch ignore")
           conn
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  def build(%Config{version: version, app: app, build: %BuildConfig{} = build_config} = config) do
    conn = init(config)

    workspace = build_config.workspace
    revision = build_config.revision
    target_mix_env = build_config.mix_env || "prod"

    git_push! conn, build_config
    git_reset_remote(conn, revision)
    git_clean_remote(conn, workspace)
    get_and_update_deps(conn, app, target_mix_env)
    clean_compile(conn, app, target_mix_env)
    generate_release(conn, app, target_mix_env)
    download_release_archive(conn, app, version, target_mix_env)
  end

  defp git_push!(conn, build_config) do
    user_host = "#{build_config.user}@#{build_config.host}"
    user_identity = build_config.identity
    case git_push(conn, user_host, build_config.workspace, user_identity) do
      {:ok, _} -> :ok
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  defp git_push(conn, host, workspace, identity) do
    git_push = Application.get_env(:bootleg, :push_options, "-f")
    refspec = Application.get_env(:bootleg, :refspec, "master")
    git_env = if identity, do: [{"GIT_SSH_COMMAND", "ssh -i '#{identity}'"}]
    host_url = "#{host}:#{workspace}"

    UI.puts "Pushing new commits with git to: #{host}"

    case @git.push(["--tags", git_push, host_url, refspec], env: (git_env || [])) do
      {"", 0} -> {:ok, nil}
      {res, 0} -> UI.puts_recv conn, res
                  {:ok, res}
      {res, _} -> UI.puts "ERROR: #{inspect res}"
                  {:error, res}
    end
  end

  defp git_reset_remote(ssh, revision) do
    UI.puts "Resetting remote hosts to revision \"#{revision}\""
    ssh
    |> @ssh.run!("git reset --hard #{revision}")
    |> UI.puts_recv()
  end

  defp git_clean_remote(ssh, _workspace) do
    UI.puts "Skipped cleaning generated files from last build"

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

  defp get_and_update_deps(ssh, app, target_mix_env) do
    UI.puts "Fetching / Updating dependencies"
    commands = [
      "mix local.rebar --force",
      "mix local.hex --force",
      "mix deps.get --only=prod"
    ]
    commands = Enum.map(commands, &(with_env_vars(app, target_mix_env, &1)))
    # clean fetch of dependencies on the remote build host
    @ssh.run!(ssh, commands)
  end

  defp clean_compile(ssh, app, target_mix_env) do
    UI.puts "Compiling remote build"
    commands = Enum.map(["mix deps.compile", "mix compile"], &(with_env_vars(app, target_mix_env, &1)))
    @ssh.run!(ssh, commands)
  end

  defp with_env_vars(app, mix_env, cmd) do
    "APP=#{app} MIX_ENV=#{mix_env} #{cmd}"
  end

  defp generate_release(ssh, app, target_mix_env) do
    UI.puts "Generating release"

    # build assets for phoenix apps
    @ssh.run!(ssh, "[ -f package.json ] && npm install")
    @ssh.run!(ssh, "[ -f brunch-config.js ] && [ -d node_modules ] && ./node_modules/brunch/bin/brunch b -p")
    @ssh.run!(ssh, "[ -d deps/phoenix ] && " <> with_env_vars(app, target_mix_env, "mix phoenix.digest"))

    @ssh.run!(ssh, with_env_vars(app, target_mix_env, "mix release"))
  end

  defp download_release_archive(conn, app, version, target_mix_env) do
    remote_path = "_build/#{target_mix_env}/rel/#{app}/releases/#{version}/#{app}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "build.tar.gz")

    UI.puts "Downloading release archive"
    File.mkdir_p!(local_archive_folder)

    case @ssh.download(conn, remote_path, local_path) do
      :ok -> {:ok, local_path}
      _ -> raise "Error: downloading of release archive failed"
    end
  end
end
