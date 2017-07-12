defmodule Bootleg.Strategies.Manage.Distillery do
  @moduledoc ""

  alias Bootleg.{UI, SSH, Config}

  def init do
    SSH.init(:app)
  end

  def start(conn) do
    app_name = Config.app
    SSH.run!(conn, "bin/#{app_name} start")
    UI.info "#{app_name} started"
    {:ok, conn}
  end

  def stop(conn) do
    app_name = Config.app
    SSH.run!(conn, "bin/#{app_name} stop")
    UI.info "#{app_name} stopped"
    {:ok, conn}
  end

  def restart(conn) do
    app_name = Config.app
    SSH.run!(conn, "bin/#{app_name} restart")
    UI.info "#{app_name} restarted"
    {:ok, conn}
  end

  def ping(conn) do
    app_name = Config.app
    SSH.run!(conn, "bin/#{app_name} ping")
    {:ok, conn}
  end
end
