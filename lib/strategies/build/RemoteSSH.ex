defmodule Bootleg.Strategies.Build.RemoteSSH do

  def init(config) do
    init_app_remotely(config[:host], config[:user], config[:identity], config[:workspace])
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

  def init_app_remotely(host, user, identity, workspace) do
    IO.puts "host #{host}"
    IO.puts "user #{user}"
    IO.puts "identity #{identity}"
    IO.puts "workspace #{workspace}"
    #TODO: run any pre init app remotely hooks
    conn = ssh_connect(host, user, identity)
    user_host = "#{user}@#{host}"
    {git_remote, 0} = System.cmd "git", ["remote", "-v"]
    IO.puts "Ensuring host is ready to accept git pushes"

    remote_url = "#{user_host}:#{workspace}"
    if !String.contains?(git_remote, "#{user_host}\t#{remote_url}") do
      if String.contains?(git_remote, user_host), do: System.cmd "git", ["remote", "rm", user_host]
      System.cmd "git", ["remote", "add", user_host, remote_url]
    end
    SSHKit.run conn,
      '
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
      '
    conn
    #TODO: run any post init app remotely hooks
  end


  def git_push(conn, host) do
    #TODO: run any pre git_push hooks
    git_push = Application.get_env(:bootleg, :git_push,"-f")
    refspec = Application.get_env(:bootleg, :refspec,"master")

    IO.puts "Pushing new commits with git to: #{host}"

    case System.cmd "git", ["push", "--tags", git_push, host, refspec] do
      {res, 0} -> IO.puts res
      {res, _} -> IO.puts "ERROR: #{inspect res}"
    end
    #TODO: run any post git_push hooks
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
    # TODO: migrate this logic to elixir land

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
    # TODO: execute pre erlang_get_and_update_deps hooks
    IO.puts "Fetching / Updating dependencies"

    # TODO: source some environment variables
    SSHKit.run conn,
      '
      set -e
      cd #{workspace}
      APP=#{app} MIX_ENV=#{target_mix_env} mix local.hex --force
      APP=#{app} MIX_ENV=#{target_mix_env} mix deps.get
      '
    # TODO: execute post erlang_get_and_update_deps hooks
    conn
  end

  def clean_compile(conn, workspace, app, target_mix_env) do
    IO.puts "Compiling remote build"
    # TODO: source some environment variables
    # TODO: add option for mix-clean
    # TODO: autoversion
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
    # TODO: source some environment variables
    # TODO: autoversion
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