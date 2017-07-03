defmodule Bootleg.Strategies.Manage.Distillery do
  @moduledoc ""

  alias Bootleg.{Config, Config.ManageConfig, Project, UI, SSH}

  @config_keys ~w(hosts user workspace)

  def init(%Config{manage: %ManageConfig{identity: identity, hosts: hosts, user: user, workspace: workspace} = config}, %Project{} = _project) do
    with :ok <- Bootleg.check_config(config, @config_keys) do
      SSH.init(hosts,
               [user: user, identity: identity, workspace: workspace, create_workspace: false])
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  def start(conn, _config, %Project{} = project) do
    SSH.run!(conn, "bin/#{project.app_name} start")
    UI.info "#{project.app_name} started"
    {:ok, conn}
  end

  def stop(conn, _config, %Project{} = project) do
    SSH.run!(conn, "bin/#{project.app_name} stop")
    UI.info "#{project.app_name} stopped"
    {:ok, conn}
  end

  def restart(conn, _config, %Project{} = project) do
    SSH.run!(conn, "bin/#{project.app_name} restart")
    UI.info "#{project.app_name} restarted"
    {:ok, conn}
  end

  def ping(conn, _config, %Project{} = project) do
    SSH.run!(conn, "bin/#{project.app_name} ping")
    {:ok, conn}
  end

  def migrate(conn, %Config{manage: %ManageConfig{migration_module: mod, migration_function: fun}} = config, %Project{} = project) do
    case Bootleg.check_config(config.manage, ~w(migration_module)) do
       :ok -> SSH.run!(conn, "bin/#{project.app_name} rpcterms Elixir.#{mod} #{fun || :migrate} '#{project.app_name}.'")
       {:error, msg} -> raise "Error: #{msg}"
    end
    UI.info "#{project.app_name} migrated"
  end
end
