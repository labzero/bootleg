defmodule Bootleg.Strategies.Build.RemoteSSH do
  @moduledoc ""

  def init(config) do
    with {:ok, remotes} <- parse_git_remotes() do
      init_app_remotely(config[:host], config[:user], config[:identity], config[:workspace], remotes)
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
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
    cb = SSHKit.SSH.ClientKeyAPI.with_options(identity: File.open!(identity, [:read]))
    host = %SSHKit.Host{name: host, options: [key_cb: cb, user: user]}    
    context = SSHKit.context(host)
    context
  end

  def build(conn, config, _version) do
    user_host = "#{config[:user]}@#{config[:host]}"
    workspace = config[:workspace]
    revision = config[:revision]
    target_mix_env = config[:mix_env] || "prod"
    app = config[:app]
    
    conn
    |> git_push(user_host)
    |> git_reset_remote(workspace, revision)
    |> git_clean_remote(workspace)
    |> get_and_update_deps(workspace, app, target_mix_env)
    |> clean_compile(workspace, app, target_mix_env)
    |> generate_release(workspace, app, target_mix_env)
    |> download_release_archive(workspace, app, target_mix_env, config)
  end

  def init_app_remotely(host, user, identity, workspace, remotes) do
    IO.puts "host #{host}"
    IO.puts "user #{user}"
    IO.puts "identity #{identity}"
    IO.puts "workspace #{workspace}"
    conn = ssh_connect(host, user, identity)
    user_host = "#{user}@#{host}"
    
    IO.puts "Ensuring host is ready to accept git pushes"

    remote_url = "#{user_host}:#{workspace}"
    if !String.contains?(remotes, "#{user_host}\t#{remote_url}") do
      if String.contains?(remotes, user_host), do: System.cmd "git", ["remote", "rm", user_host]
      System.cmd "git", ["remote", "add", user_host, remote_url]
    end
    SSHKit.run conn,
      "
      set -e
      if [ ! -d #{workspace} ]
      then
        mkdir -p #{workspace}
        cd #{workspace}
        git init 
        git config receive.denyCurrentBranch ignore
      else
        cd #{workspace}
        git config receive.denyCurrentBranch ignore
      fi
      "
    conn
  end


  def git_push(conn, host) do
    git_push = Application.get_env(:bootleg, :git_push, "-f")
    refspec = Application.get_env(:bootleg, :refspec, "master")

    IO.puts "Pushing new commits with git to: #{host}"

    case System.cmd "git", ["push", "--tags", git_push, host, refspec] do
      {res, 0} -> IO.puts res
      {res, _} -> IO.puts "ERROR: #{inspect res}"
    end
    conn
  end

  def git_reset_remote(conn, workspace, revision) do
    IO.puts "Resetting remote hosts to #{revision}"
    SSHKit.run conn,
      '
      set -e
      cd #{workspace}
      git reset --hard #{revision}
      '
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

    SSHKit.run conn,
      '
      set -e
      cd #{workspace}
      APP=#{app} MIX_ENV=#{target_mix_env} mix local.hex --force
      APP=#{app} MIX_ENV=#{target_mix_env} mix deps.get
      '
    conn
  end

  def clean_compile(conn, workspace, app, target_mix_env) do
    IO.puts "Compiling remote build"
    SSHKit.run conn,
      '
      set -e
      cd #{workspace}
      APP=#{app} MIX_ENV=#{target_mix_env} mix do deps.compile, compile
      '
    conn
  end

  def generate_release(conn, workspace, app, target_mix_env) do
    IO.puts "Generating release"
    SSHKit.run conn,
      '
      set -e
      cd #{workspace}
      APP=#{app} MIX_ENV=#{target_mix_env} mix release
      '
    conn
  end

  def download_release_archive(_conn, workspace, app, target_mix_env, config) do
    cb = SSHKit.SSH.ClientKeyAPI.with_options(identity: File.open!(config[:identity]))
    {:ok, conn} = SSHKit.SSH.connect(config[:host], [key_cb: cb, user: config[:user]])
    source = "#{workspace}/_build/#{target_mix_env}/rel/clippyx/releases/0.2.0/#{app}.tar.gz"
    destination = "/Users/brien/dev/labzero/open_source/clippyx/#{app}.tar.gz"
    IO.puts source
    IO.puts destination
    resp = SSHKit.SCP.download(conn, source, destination)
    IO.puts inspect resp
  end
end