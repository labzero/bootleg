defmodule Bootleg.Strategies.Build.RemoteSSH do
  @moduledoc ""

  alias SSHKit.SSH
  alias SSHKit.SSH.ClientKeyAPI
  alias SSHKit.SCP

  def init(config) do
    with {:ok, config} <- check_config(config),
         :ok <- ensure_local_git_remotes(config),
         :ok <- :ssh.start(),
         {:ok, identity_file} <- File.open(config[:identity]),
         cb = ClientKeyAPI.with_options(identity: identity_file),
         {:ok, conn} <- SSH.connect(config[:host], [connect_timeout: 5000,
                                                    key_cb: cb,
                                                    user: config[:user]]),
         {:ok, _, 0} <- SSH.run(conn,
                                workspace_setup_script(config[:workspace])) do
      safe_run conn, config[:workspace], "git config receive.denyCurrentBranch ignore"
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
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

  defp check_config(config) do
    required_atoms = ~w(host user workspace revision version)a
    Enum.each(required_atoms, fn required_atom ->
      if List.keyfind(config, required_atom, 0) == nil do
        raise "Bootleg requires :#{required_atom} to be set in build configuration"
      end
    end)

    {:ok, config}
  end

  defp ensure_local_git_remotes(config) do
    with {:ok, remotes} = parse_local_git_remotes(),
         user_host = "#{config[:user]}@#{config[:host]}",
         remote_url = "#{user_host}:#{config[:workspace]}" do
      IO.puts "Ensuring host is ready push to build server"

      case String.contains?(remotes, "#{user_host}\t#{remote_url}") do
        true -> :ok
        false -> add_local_git_remote(user_host, remote_url)
      end
    end
  end

  defp add_local_git_remote(user_host, remote_url) do
    case System.cmd("git",
                    ["remote", "add", user_host, remote_url],
                    stderr_to_stdout: true) do
      {_, 0} -> :ok
      {msg, 1} -> {:error, "git: #{msg}"}
      {_, 128} -> {:error, "Bootleg requires a Git repository."}
    end
  catch
    ErlangError -> {:error, "Bootleg requires Git to be installed."}
  end

  defp parse_local_git_remotes do
    case System.cmd("git", ["remote", "-v"], stderr_to_stdout: true) do
      {remotes, 0} -> {:ok, remotes}
      {msg, 1} -> {:error, "git: #{msg}"}
      {_, 128} -> {:error, "Bootleg requires a Git repository."}
    end
  catch
    ErlangError -> {:error, "Bootleg requires Git to be installed."}
  end

  defp git_push(conn, host) do
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

  defp git_reset_remote(conn, workspace, revision) do
    IO.puts "Resetting remote hosts to revision \"#{revision}\""
    safe_run conn, workspace,
      "git reset --hard #{revision}"
    conn
  end

  defp git_clean_remote(conn, _workspace) do
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

  defp get_and_update_deps(conn, workspace, app, target_mix_env) do
    IO.puts "Fetching / Updating dependencies"

    # clean fetch of dependencies on the remote build host
    safe_run conn, workspace,
      [
        "APP=#{app} MIX_ENV=#{target_mix_env} mix local.rebar --force",
        "APP=#{app} MIX_ENV=#{target_mix_env} mix local.hex --force",
        "APP=#{app} MIX_ENV=#{target_mix_env} mix deps.get --only=prod"
      ]
    conn
  end

  defp clean_compile(conn, workspace, app, target_mix_env) do
    IO.puts "Compiling remote build"
    safe_run conn, workspace,
      [
        "APP=#{app} MIX_ENV=#{target_mix_env} mix deps.compile",
        "APP=#{app} MIX_ENV=#{target_mix_env} mix compile"
      ]
    conn
  end

  defp generate_release(conn, workspace, app, target_mix_env) do
    IO.puts "Generating release"

    safe_run conn, workspace,
      "APP=#{app} MIX_ENV=#{target_mix_env} mix release"
  end

  defp safe_run(conn, working_directory, cmd) when is_list(cmd) do
    Enum.each(cmd, fn cmd ->
      safe_run(conn, working_directory, cmd)
    end)
    conn
  end

  defp safe_run(conn, working_directory, cmd) when is_binary(cmd) do
    IO.puts " -> $ #{cmd}"
    case SSH.run conn,
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

  defp download_release_archive(conn, workspace, app, version, target_mix_env) do
    remote_path = "#{workspace}/_build/#{target_mix_env}/rel/#{app}/releases/#{version}/#{app}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{app}-#{version}.tar.gz")

    IO.puts "Downloading release archive"
    IO.puts " -> remote: #{remote_path}"
    IO.puts " <-  local: #{local_path}"

    File.mkdir_p!(local_archive_folder)

    case SCP.download(conn, remote_path, local_path) do
      :ok -> conn
      _ -> raise "Error: downloading of release archive failed"
    end
  end
end
