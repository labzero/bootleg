defmodule Bootleg.Strategies.Manage.Distillery do
  @moduledoc ""

  @ssh Application.get_env(:bootleg, :ssh, Bootleg.SSH)

  alias Bootleg.{Config, ManageConfig, UI}

  @config_keys ~w(hosts user workspace)

  def init(%Config{manage: %ManageConfig{identity: identity, hosts: hosts, user: user, workspace: workspace} = config}) do
    with :ok <- Bootleg.check_config(config, @config_keys) do
      @ssh.init(hosts, user, [identity: identity, workspace: workspace])
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  def start(conn, %Config{app: app}) do
    @ssh.run!(conn, "bin/#{app} start")
    UI.info "#{app} started"
    {:ok, conn}
  end

  def stop(conn, %Config{app: app}) do
    @ssh.run!(conn, "bin/#{app} stop")
    UI.info "#{app} stopped"
    {:ok, conn}
  end

  def restart(conn, %Config{app: app}) do
    @ssh.run!(conn, "bin/#{app} restart")
    UI.info "#{app} restarted"
    {:ok, conn}
  end

  def ping(conn, %Config{app: app}) do
    @ssh.run!(conn, "bin/#{app} ping")
    {:ok, conn}
  end

  def migrate(conn, %Config{app: app, manage: %ManageConfig{migration_module: mod, migration_function: fun}} = config) do
    case Bootleg.check_config(config.manage, ~w(migration_module)) do
       :ok -> @ssh.run!(conn, "bin/#{app} rpcterms Elixir.#{mod} #{fun || :migrate} '#{app}.'")
       {:error, msg} -> raise "Error: #{msg}"
    end
    UI.info "#{app} migrated"
  end
end
