defmodule Bootleg.Strategies.Manage.DistilleryFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.{Strategies.Manage.Distillery, SSH}
  import ExUnit.CaptureIO

  setup %{hosts: [host]} do
    use Bootleg.Config
    role :app, [host.ip], port: host.port, user: host.user, password: host.password,
      silently_accept_hosts: true, workspace: "workspace"

    config :app, "build_me"
    config :version, "0.1.0"

    capture_io(fn ->
      conn = SSH.init(:app)
      SSH.run!(conn, "install-app build_me")
      send(self(), {:connection, conn})
    end)
    assert_received {:connection, conn}

    %{conn: conn}
  end

  @tag boot: 1
  test "init/0", %{hosts: [host]} do
    capture_io(fn ->
      assert %SSHKit.Context{
        hosts: [%SSHKit.Host{name: hostname, options: options}], path: "workspace", user: nil
      } = Distillery.init()
      assert hostname == host.ip
      assert options[:user] == host.user
      assert options[:silently_accept_hosts] == true
      assert options[:port] == host.port
    end)
  end

  @tag boot: 1
  test "init/0 failure", %{hosts: [host]} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config
    role :app, ["bad-host.local"], port: host.port, user: host.user, password: host.password,
      silently_accept_hosts: true, workspace: "workspace"

    capture_io(fn ->
      assert_raise SSHError, fn -> Distillery.init() end
    end)
  end

  @tag boot: 1
  test "start/1", %{conn: conn} do
    capture_io(fn ->
      assert {:ok, %SSHKit.Context{}} = Distillery.start(conn)
    end)
  end

  @tag boot: 1
  test "start/1 with app running", %{conn: conn} do
    capture_io(fn ->
      SSH.run!(conn, "bin/build_me start")
      assert {:ok, %SSHKit.Context{}} = Distillery.start(conn)
    end)
  end

  @tag boot: 1
  test "stop/1", %{conn: conn} do
    capture_io(fn ->
      SSH.run!(conn, "launch-app build_me")
      assert {:ok, %SSHKit.Context{}} = Distillery.stop(conn)
    end)
  end

  @tag boot: 1
  test "stop/1 with app not running", %{conn: conn} do
    capture_io(fn ->
      assert_raise SSHError, fn -> Distillery.stop(conn) end
    end)
  end

  @tag boot: 1
  test "restart/1", %{conn: conn} do
    capture_io(fn ->
      SSH.run!(conn, "launch-app build_me")
      assert {:ok, %SSHKit.Context{}} = Distillery.restart(conn)
    end)
  end

  @tag boot: 1
  test "restart/1 with app not running", %{conn: conn} do
    capture_io(fn ->
      assert_raise SSHError, fn -> Distillery.restart(conn) end
    end)
  end

  @tag boot: 1
  test "ping/1", %{conn: conn} do
    capture_io(fn ->
      SSH.run!(conn, "launch-app build_me")
      assert {:ok, %SSHKit.Context{}} = Distillery.ping(conn)
    end)
  end

  @tag boot: 1
  test "ping/1 with app not running", %{conn: conn} do
    capture_io(fn ->
      assert_raise SSHError, fn -> Distillery.ping(conn) end
    end)
  end
end
