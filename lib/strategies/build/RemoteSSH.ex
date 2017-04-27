defmodule Bootleg.Strategies.Build.RemoteSSH do

  @moduledoc ""

  @ssh Application.get_env(:bootleg, :ssh) || Bootleg.SSH
  @shell Application.get_env(:bootleg, :shell) || Bootleg.Shell
  @git Application.get_env(:bootleg, :git) || Bootleg.Git

  alias Bootleg.Config
  alias Bootleg.BuildConfig

  def init(%Config{build: %BuildConfig{identity: identity, workspace: workspace, host: host, user: user} = config}) do
    with {:ok, config} <- check_config(config),
         :ok <- @ssh.start() do
           host 
           |> @ssh.connect(user, identity)
           |> @ssh.run!(workspace_setup_script(workspace))
           |> @ssh.run!("git config receive.denyCurrentBranch ignore", workspace)    
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end
  
  def build(%Config{version: version, app: app, build: %BuildConfig{} = build_config} = config) do
    conn = init(config)
    user_host = "#{build_config.user}@#{build_config.host}"
    user_identity = build_config.identity
    workspace = build_config.workspace
    revision = build_config.revision
    target_mix_env = build_config.mix_env || "prod"
    case git_push(user_host, workspace, user_identity) do
      {:ok, _} -> :ok
      {:error, msg} -> raise "Error: #{msg}"
    end

    conn
    |> git_reset_remote(workspace, revision)
    |> git_clean_remote(workspace)
    |> get_and_update_deps(workspace, app, target_mix_env)
    |> clean_compile(workspace, app, target_mix_env)
    |> generate_release(workspace, app, target_mix_env)
    |> download_release_archive(workspace, app, version, target_mix_env)
  end

  defp workspace_setup_script(workspace) do
      "
      set -e
      if [ ! -d #{workspace} ]
      then
        mkdir -p #{workspace}
        cd #{workspace}
        git init 
      fi
      "
  end

  defp check_config(%BuildConfig{} = config) do
    missing =  Enum.filter(~w(host user workspace revision), &(Map.get(config, &1, 0) == nil))
    if Enum.count(missing) > 0 do
      raise "RemoteSSH build strategy requires #{inspect Map.keys(missing)} to be set in the build configuration"
    end
    {:ok, config}        
  end

  defp git_push(host, workspace, identity) do
    git_push = Application.get_env(:bootleg, :push_options, "-f")
    refspec = Application.get_env(:bootleg, :refspec, "master")
    git_env = if identity, do: [{"GIT_SSH_COMMAND", "ssh -i '#{identity}'"}]
    host_url = "#{host}:#{workspace}"

    IO.puts "Pushing new commits with git to: #{host}"
    
    case @git.push(["--tags", git_push, host_url, refspec], env: (git_env || [])) do
      {"", 0} -> {:ok, nil}
      {res, 0} -> IO.puts res
                  {:ok, res}
      {res, _} -> IO.puts "ERROR: #{inspect res}"
                  {:error, res}
    end
  end

  defp git_reset_remote(ssh, workspace, revision) do
    IO.puts "Resetting remote hosts to revision \"#{revision}\""
    @ssh.run!(ssh, "git reset --hard #{revision}", workspace)
  end

  defp git_clean_remote(ssh, _workspace) do
    IO.puts "Skipped cleaning generated files from last build"

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

  defp get_and_update_deps(ssh, workspace, app, target_mix_env) do
    IO.puts "Fetching / Updating dependencies"
    commands = [
      "mix local.rebar --force",
      "mix local.hex --force",
      "mix deps.get --only=prod"
    ]
    commands = Enum.map(commands, &(with_env_vars(app, target_mix_env, &1)))
    # clean fetch of dependencies on the remote build host
    @ssh.run!(ssh, commands, workspace)    
  end

  defp clean_compile(ssh, workspace, app, target_mix_env) do
    IO.puts "Compiling remote build"
    commands = Enum.map(["mix deps.compile", "mix compile"], &(with_env_vars(app, target_mix_env, &1)))
    @ssh.run!(ssh, commands, workspace)      
  end

  defp with_env_vars(app, mix_env, cmd) do
    "APP=#{app} MIX_ENV=#{mix_env} #{cmd}"    
  end
   
  defp generate_release(ssh, workspace, app, target_mix_env) do
    IO.puts "Generating release"
    @ssh.run!(ssh, with_env_vars(app, target_mix_env, "mix release"), workspace)
  end

  defp download_release_archive(conn, workspace, app, version, target_mix_env) do
    remote_path = "#{workspace}/_build/#{target_mix_env}/rel/#{app}/releases/#{version}/#{app}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{app}-#{version}.tar.gz")

    IO.puts "Downloading release archive"
    IO.puts " -> remote: #{remote_path}"
    IO.puts " <-  local: #{local_path}"

    File.mkdir_p!(local_archive_folder)

    case @ssh.download(conn, remote_path, local_path) do
      :ok -> conn
      msg -> raise "Error: downloading of release archive failed #{inspect msg}"
    end
  end
end
