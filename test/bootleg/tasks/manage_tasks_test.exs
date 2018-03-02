defmodule Bootleg.Tasks.ManageTasksTest do
  use Bootleg.FunctionalCase, async: false
  use Bootleg.DSL
  alias Bootleg.SSH
  import ExUnit.CaptureIO

  setup %{hosts: [host]} do
    use Bootleg.DSL

    role(
      :app,
      [host.ip],
      port: host.port,
      user: host.user,
      password: host.password,
      silently_accept_hosts: true,
      workspace: "workspace"
    )

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

  test "start" do
    capture_io(fn ->
      assert :ok = invoke(:start)
    end)
  end

  test "invoke start with app running", %{conn: conn} do
    capture_io(fn ->
      SSH.run!(conn, "bin/build_me start")
      assert :ok = invoke(:start)
    end)
  end

  test "invoke stop", %{conn: conn} do
    capture_io(fn ->
      SSH.run!(conn, "launch-app build_me")
      assert :ok = invoke(:stop)
    end)
  end

  test "invoke stop with app not running" do
    capture_io(fn ->
      assert_raise SSHError, fn -> invoke(:stop) end
    end)
  end

  test "invoke restart", %{conn: conn} do
    capture_io(fn ->
      SSH.run!(conn, "launch-app build_me")
      assert :ok = invoke(:restart)
    end)
  end

  test "invoke restart with app not running" do
    capture_io(fn ->
      assert_raise SSHError, fn -> invoke(:restart) end
    end)
  end

  test "invoke ping", %{conn: conn} do
    capture_io(fn ->
      SSH.run!(conn, "launch-app build_me")
      assert :ok = invoke(:ping)
    end)
  end

  test "invoke ping with app not running" do
    capture_io(fn ->
      assert_raise SSHError, fn -> invoke(:ping) end
    end)
  end
end
