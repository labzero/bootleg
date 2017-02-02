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

    build_host = "ec2-54-202-189-109.us-west-2.compute.amazonaws.com"
    build_at = "/tmp/bootleg/build"
    revision = Application.get_env(:bootleg, :revision, "HEAD")
    host_user  = "ubuntu" #? could just require .ssh/config be setup with this
    user_host = "#{host_user}@#{build_host}"
    app = Application.get_env(:bootleg, :app)
    target_mix_env = Application.get_env(:bootleg, :mix_env, "dev")

#  authorize_hosts
    ssh_connect(build_host, host_user)
    |> init_app_remotely(build_host, host_user, build_at)
    |> git_push(user_host)
    |> git_reset_remote(build_at, revision)
    |> git_clean_remote(build_at)
    |> get_and_update_deps(build_at, app, target_mix_env)
    |> clean_compile(build_at, app, target_mix_env)
    |> generate_release(build_at, app, target_mix_env)
    |> copy_release_to_release_store
  end

  def ssh_connect(host, user) do
    user_dir = Path.join([File.cwd!, "priv", ".ssh"])
    :ssh.start
    {:ok, host_ip} = :inet.getaddr(to_charlist(host), :inet)
    case SSHEx.connect( user_dir: to_charlist(user_dir),
                        ip: :inet_parse.ntoa(host_ip),
                        user: to_charlist(user),
                        silently_accept_hosts: true) do
      {:ok, conn} -> conn
      {:error, message} -> IO.puts "Unable to connect: #{message}"
    end
  end

  def init_app_remotely(conn, hosts, user_host, build_at) do
    #TODO: run any pre init app remotely hooks

    {git_remote, 0} = System.cmd "git", ["remote", "-v"]
    IO.puts "Ensuring host is ready to accept git pushes"

    remote_url = "#{user_host}:#{build_at}"
    if !String.contains?(git_remote, "#{user_host}\t#{remote_url}") do
      if String.contains?(git_remote, user_host), do: System.cmd "git", ["remote", "rm", user_host]
      System.cmd "git", ["remote", "add", user_host, remote_url]
    end
    case SSHEx.run conn,
      '
      set -e
      if [ ! -d #{build_at} ]
      then
        mkdir -p #{build_at}
        cd #{build_at}
        git init 
        git config receive.denyCurrentBranch ignore
      else
        cd #{build_at}
        git config receive.denyCurrentBranch ignore
      fi
      ' do
      {:error, message} -> IO.puts message
      {:ok, resp, 0} -> IO.puts(resp)
    end
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

  def git_reset_remote(conn, build_at, revision) do
    IO.puts "Resetting remote hosts to #{revision}"
    {:ok, resp, 0} = SSHEx.run conn,
      '
      set -e
      cd #{build_at}
      git reset --hard #{revision}
      '
    IO.puts resp
    conn
  end

  def git_clean_remote(conn, build_at) do
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
  def get_and_update_deps(conn, build_at, app, target_mix_env) do
    # TODO: execute pre erlang_get_and_update_deps hooks

    IO.puts "Fetching / Updating dependencies"
    # TODO: source some environment variables
    {:ok, resp, 0} = SSHEx.run conn,
      '
      set -e
      cd #{build_at}
      APP=#{app} MIX_ENV=#{target_mix_env} mix local.hex --force
      APP=#{app} MIX_ENV=#{target_mix_env} mix deps.get
      '
    IO.puts resp
    # TODO: execute post erlang_get_and_update_deps hooks
    conn
  end

  def clean_compile(conn, build_at, app, target_mix_env) do
    IO.puts "Compiling remote build"
    # TODO: source some environment variables
    # TODO: add option for mix-clean
    # TODO: autoversion
    stream = SSHEx.stream conn,
      '
      set -e
      cd #{build_at}
      APP=#{app} MIX_ENV=#{target_mix_env} mix do deps.compile, compile
      '
    Enum.each(stream, fn(x)->
      case x do
        {:status,status} -> nil
        {:error,reason}  -> IO.puts(reason)
        {_,row} -> IO.puts(row)
      end
    end)
    conn
  end

  def generate_release(conn, build_at, app, target_mix_env) do
    IO.puts "Generating release"
    # TODO: source some environment variables
    # TODO: autoversion
    stream = SSHEx.stream conn,
      '
      set -e
      cd #{build_at}
      APP=#{app} MIX_ENV=#{target_mix_env} mix release
      '
    Enum.each(stream, fn(x)->
      case x do
        {:status,status} -> nil
        {:error,reason}  -> IO.puts(reason)
        {_,row} -> IO.puts(row)
      end
    end)
    conn
  end

end