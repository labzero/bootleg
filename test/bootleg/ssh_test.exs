defmodule Bootleg.SSHTest do
  use Bootleg.TestCase, async: false
  alias Bootleg.{Host, SSH}
  alias SSHKit.Context
  alias SSHKit.Host, as: SSHKitHost
  import ExUnit.CaptureIO

  doctest SSH

  setup do
    tmp_file_path = "/tmp/bootleg_test_key_rsa"
    File.touch(tmp_file_path)

    on_exit(fn ->
      File.rm(tmp_file_path)
    end)

    %{
      conn: %Context{
        path: ".",
        hosts: [
          %Host{host: %SSHKitHost{name: "localhost.1", options: []}, options: []},
          %Host{host: %SSHKitHost{name: "localhost.2", options: []}, options: []}
        ]
      },
      blank_key_path: tmp_file_path
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
        host = %Host{
          host: %SSHKitHost{name: "localhost.1", options: [identity: "foo"]},
          options: []
        }

        SSH.ssh_host_options(host)
      end
    end)
  end

  test "ssh_opts/1 discards nil value options" do
    options = [port: nil, user: "foobar"]
    assert [user: "foobar"] == SSH.ssh_opts(options)
  end

  test "ssh_opts/1 allows arbitrary options" do
    options = [foobar: true, user: "foobar"]
    assert [foobar: true, user: "foobar"] == SSH.ssh_opts(options)
  end

  test "ssh_opts/1 discards identity with nil value" do
    options = [identity: nil]
    assert [] == SSH.ssh_opts(options)
  end

  test "ssh_opts/1 with identity returns a key callback", %{blank_key_path: blank_key_path} do
    options = [identity: blank_key_path]
    [key_cb: {SSHClientKeyAPI, _}] = SSH.ssh_opts(options)
  end

  test "ssh_opts/1 with identity and options returns a key callback with same options", %{
    blank_key_path: blank_key_path
  } do
    options = [identity: blank_key_path, silently_accept_hosts: false]
    [key_cb: {SSHClientKeyAPI, keyopts}, silently_accept_hosts: false] = SSH.ssh_opts(options)
    map_opts = Enum.into(keyopts, %{})
    %{silently_accept_hosts: false} = map_opts
  end

  test "merge_run_results/2" do
    assert [[2, 4, 1, 2]] = SSH.merge_run_results([[1, 2]], [[2, 4]])

    assert [[2, 4, 1, 2], [5, 6, 3, 4]] =
             SSH.merge_run_results([[1, 2], [3, 4]], [[2, 4], [5, 6]])

    assert [1, 2] = SSH.merge_run_results([1, 2], [])
    assert [[1, 2]] = SSH.merge_run_results([[1, 2]], [])
    assert [[1, 2]] = SSH.merge_run_results([], [[1, 2]])
    assert [[2, 1], [4]] = SSH.merge_run_results([1], [2, 4])
    assert [[1, 2], [4]] = SSH.merge_run_results([2, 4], [1])
  end

  test "supported_options/0" do
    assert Enum.member?(SSH.supported_options(), :quiet_mode)
  end
end
