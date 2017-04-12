defmodule Bootleg.Strategies.Build.RemoteSSH do
  @moduledoc ""

  def init(config) do
    with {:ok, remotes} <- parse_git_remotes(),
         {:ok, config} <- check_config(config) do
      init_app_remotely(config[:host], config[:user], config[:identity], config[:workspace], remotes)
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  @doc """
  Insist that the user-defined Bootleg configuration include 
  all mandatory settings.
  """
  def check_config(config) do
    required_atoms = ~w(host user workspace revision version)a
    Enum.each(required_atoms, fn required_atom ->
      if List.keyfind(config, required_atom, 0) == nil do
        raise "Bootleg requires :#{required_atom} to be set in build configuration"
      end
    end)

    {:ok, config}
  end

  def parse_git_remotes() do
    try do
      case System.cmd("git", ["remote", "-v"], stderr_to_stdout: true) do
        {remotes, 0} -> {:ok, remotes}
        {msg, 1} -> {:error, "git: #{msg}"}
        {_, 128} -> {:error, "Bootleg requires a Git repository."}
      end
    rescue
      ErlangError -> {:error, "Bootleg requires Git to be installed."}
    end
  end

  def ssh_connect(host, user, identity) do
    :ssh.start
    cb = SSHKit.SSH.ClientKeyAPI.with_options(identity: File.open!(identity))
    {:ok, conn} = SSHKit.SSH.connect(host, [key_cb: cb, user: user])
    conn
  end

  def build(conn, config, _version) do
    user_host = "#{config[:user]}@#{config[:host]}"
    workspace = config[:workspace]
    revision = config[:revision]
    version = config[:version]
    target_mix_env = config[:mix_env] || "prod"
    app = config[:app]

    conn
    |> git_push(user_host)
    |> git_reset_remote(workspace, revision)
    |> git_clean_remote(workspace)
    |> get_and_update_deps(workspace, app, target_mix_env)
    |> clean_compile(workspace, app, target_mix_env)
    |> generate_release(workspace, app, target_mix_env)
    |> download_release_archive(workspace, app, version, target_mix_env, config)
  end

  def init_app_remotely(host, user, identity, workspace, remotes) do
    conn = ssh_connect(host, user, identity)
    user_host = "#{user}@#{host}"
    
    IO.puts "Ensuring host is ready to accept git pushes"

    remote_url = "#{user_host}:#{workspace}"
    if !String.contains?(remotes, "#{user_host}\t#{remote_url}") do
      if String.contains?(remotes, user_host), do: System.cmd "git", ["remote", "rm", user_host]
      System.cmd "git", ["remote", "add", user_host, remote_url]
    end

    {:ok, _, 0} = SSHKit.SSH.run conn,
      "
      set -e
      if [ ! -d #{workspace} ]
      then
        mkdir -p #{workspace}
        cd #{workspace}
        git init 
      fi
      "

    safe_run conn, workspace, "git config receive.denyCurrentBranch ignore"
  end


  def git_push(conn, host) do
    git_push = Application.get_env(:bootleg, :git_push, "-f")
    refspec = Application.get_env(:bootleg, :refspec, "master")

    IO.puts "Pushing new commits with git to: #{host}"

    case System.cmd "git", ["push", "--tags", git_push, host, refspec] do
      {"", 0} -> true
      {res, 0} -> IO.puts res
      {res, _} -> IO.puts "ERROR: #{inspect res}"
    end
    conn
  end

  def git_reset_remote(conn, workspace, revision) do
    IO.puts "Resetting remote hosts to revision \"#{revision}\""
    safe_run conn, workspace,
      "git reset --hard #{revision}"
    conn
  end

  def git_clean_remote(conn, _workspace) do
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
    conn
  end

  # clean fetch of dependencies on the remote build host
  def get_and_update_deps(conn, workspace, app, target_mix_env) do
    IO.puts "Fetching / Updating dependencies"

    safe_run conn, workspace,
      [
        "APP=#{app} MIX_ENV=#{target_mix_env} mix local.rebar --force",
        "APP=#{app} MIX_ENV=#{target_mix_env} mix local.hex --force",
        "APP=#{app} MIX_ENV=#{target_mix_env} mix deps.get --only=prod"
      ]
    conn
  end

  def clean_compile(conn, workspace, app, target_mix_env) do
    IO.puts "Compiling remote build"
    safe_run conn, workspace,
      [
        "APP=#{app} MIX_ENV=#{target_mix_env} mix deps.compile",
        "APP=#{app} MIX_ENV=#{target_mix_env} mix compile"
      ]
    conn
  end

  def generate_release(conn, workspace, app, target_mix_env) do
    IO.puts "Generating release"

    safe_run conn, workspace,
      "APP=#{app} MIX_ENV=#{target_mix_env} mix release"
  end

  @doc """
  Runs several remote commands in sequence, aborting if one
  returns a non-zero exit status.
  """
  def safe_run(conn, working_directory, cmd) when is_list(cmd) do
    Enum.each(cmd, fn cmd ->
      safe_run(conn, working_directory, cmd)
    end)
    conn
  end

  @doc """
  Runs a remote command within the given working directory
  and raises an error for any non-zero exit status.
  """
  def safe_run(conn, working_directory, cmd) when is_binary(cmd) do
    IO.puts " -> $ #{cmd}"
    case SSHKit.SSH.run conn,
        "set -e;cd #{working_directory};#{cmd}" do
      {:ok, _, 0} -> conn
      {:ok, output, status} -> raise format_remote_error(cmd, output, status)
    end
  end

  defp format_remote_error(cmd, output, status) do
    "Remote command exited with non-zero status (#{status})
         cmd: \"#{cmd}\"
      stderr: #{parse_remote_output(output[:stderr])}
      stdout: #{parse_remote_output(output[:normal])}
     "
  end

  defp parse_remote_output(nil), do: ""
  defp parse_remote_output(out) do
    String.trim_trailing(out)
  end

  def download_release_archive(conn, workspace, app, version, target_mix_env, _) do
    remote_path = "#{workspace}/_build/#{target_mix_env}/rel/#{app}/releases/#{version}/#{app}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{app}-#{version}.tar.gz")
    
    IO.puts "Downloading release archive"
    IO.puts " -> remote: #{remote_path}"
    IO.puts " <-  local: #{local_path}"

    File.mkdir_p!(local_archive_folder)

    case SSHKit.SCP.download(conn, remote_path, local_path) do
      :ok -> conn
      _ -> raise "Error: downloading of release archive failed"
    end
  end
end