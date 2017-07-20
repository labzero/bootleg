defmodule Bootleg.SSHTest do
  use ExUnit.Case, async: false
  alias Bootleg.{SSH, Host}
  alias SSHKit.Context
  alias SSHKit.Host, as: SSHKitHost
  import ExUnit.CaptureIO

  doctest SSH

  setup do
    %{
      conn: %Context{
        path: ".",
        hosts: [
          %Host{host: %SSHKitHost{name: "localhost.1", options: []}, options: []},
          %Host{host: %SSHKitHost{name: "localhost.2", options: []}, options: []}
        ]
      }
    }
  end

  test "init/3 raises an error if the host is not found" do
    host = Bootleg.Host.init("bad-host-name.local", [], [])
    capture_io(fn ->
      assert_raise SSHError, fn -> SSH.init(host, []) end
    end)
  end

  test "run!/2 raises an error if the host is not found" do
    capture_io(fn ->
      conn = SSHKit.context(SSHKit.host("bad-host-name.local"))
      assert_raise SSHError, fn -> SSH.run!(conn, "echo foo") end
    end)
  end

  test "ssh_host_options/1 returns host options", %{conn: conn} do
    host = List.first(conn.hosts)
    assert %SSHKitHost{name: "localhost.1", options: []} == SSH.ssh_host_options(host)
  end

  test "ssh_host_options/1 with a malformed identity path" do
    capture_io(fn ->
      assert_raise File.Error, fn ->
        host = %Host{host: %SSHKitHost{name: "localhost.1", options: [identity: "foo"]}, options: []}
        SSH.ssh_host_options(host)
      end
    end)
  end

  test "merge_run_results/2" do
    assert [[2, 4, 1, 2]] = SSH.merge_run_results([[1, 2]], [[2, 4]])
    assert [[2, 4, 1, 2], [5, 6, 3, 4]] = SSH.merge_run_results([[1, 2], [3, 4]], [[2, 4], [5, 6]])
    assert [1, 2] = SSH.merge_run_results([1, 2], [])
    assert [[1, 2]] = SSH.merge_run_results([[1, 2]], [])
  end
end
