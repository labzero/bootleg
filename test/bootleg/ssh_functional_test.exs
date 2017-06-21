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
      assert [{:ok, [normal: "Badgers"], 0, _}] = SSH.run!(conn, "uname")
    end)
  end
end
