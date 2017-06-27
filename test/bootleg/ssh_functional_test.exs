defmodule Bootleg.SSHFunctionalTest do
  use Bootleg.FunctionalCase, async: true
  alias Bootleg.SSH
  import ExUnit.CaptureIO

  @defaults [silently_accept_hosts: true]

  @tag boot: 1
  test "run!/2", %{hosts: [host]} do
    options = [port: host.port, user: host.user, password: host.password]
    capture_io(fn ->
      conn = SSH.init(host.ip, Keyword.merge(@defaults, options))
      assert [{:ok, [stdout: "Linux\n"], 0, _}] = SSH.run!(conn, "uname")
    end)
  end

  @tag boot: 1
  test "init/3 raises an error if the host refuses the connection", %{hosts: [host]} do
    capture_io(fn ->
      assert_raise SSHError, fn -> SSH.init(host.ip, @defaults) end
    end)
  end

  @tag boot: 1
  test "run!/2 raises an error if the host refuses the connection", %{hosts: [host]} do
    capture_io(fn ->
      conn = SSHKit.context(SSHKit.host(host.ip, @defaults))
      assert_raise SSHError, fn -> SSH.run!(conn, "echo foo") end
    end)
  end
end
