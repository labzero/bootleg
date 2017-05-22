defmodule Bootleg.Strategies.Manage.Distillery do
  @moduledoc ""

  @ssh Application.get_env(:bootleg, :ssh) || Bootleg.SSH

  alias Bootleg.{Config, ManageConfig}

  @config_keys ~w(hosts user workspace)

  def init(%Config{manage: %ManageConfig{identity: identity, hosts: hosts, user: user, workspace: workspace} = config}) do
    with :ok <- Bootleg.check_config(config, @config_keys),
         :ok <- @ssh.start() do
           @ssh.connect(hosts, user, [identity: identity, workspace: workspace])
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  def start(conn, %Config{app: app}) do
    @ssh.run!(conn, "bin/#{app} start")
    IO.puts "#{app} started"
    {:ok, conn}
  end

  def stop(conn, %Config{app: app}) do
    @ssh.run!(conn, "bin/#{app} stop")
    IO.puts "#{app} stopped"
    {:ok, conn}
  end

  def restart(conn, %Config{app: app}) do
    @ssh.run!(conn, "bin/#{app} restart")
    IO.puts "#{app} restarted"
    {:ok, conn}
  end

  def ping(conn, %Config{app: app}) do
    @ssh.run!(conn, "bin/#{app} ping")
    {:ok, conn}
  end
end
