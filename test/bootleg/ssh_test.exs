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
      blank_key_path: tmp_file_path,
      host_with_identity: %Host{host: %SSHKitHost{}, options: %{identity: tmp_file_path}}
    }
  end

  test "init/3 raises an error if the host is not found" do
    host = Bootleg.Host.init("bad-host-name.local", [])

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
          host: %SSHKitHost{name: "localhost.1", options: []},
          options: [identity: "foo"]
        }

        SSH.ssh_host_options(host)
      end
    end)
  end

  test "ssh_host_options/1 with an identity", %{host_with_identity: host} do
    %SSHKit.Host{
      options: [
        key_cb: _
      ]
    } = SSH.ssh_host_options(host)
  end

  test "ssh_host_options/1 with public key and passphrase", %{host_with_identity: host} do
    host = Host.option(host, :passphrase, "foobar")

    assert %SSHKit.Host{options: [key_cb: {SSHClientKeyAPI, cb_opts}]} =
             SSH.ssh_host_options(host)

    assert cb_opts[:passphrase] == "foobar"
  end

  test "ssh_host_options/1 with public key and passphrase provider anonymous function", %{
    host_with_identity: host
  } do
    host = Host.option(host, :passphrase_provider, fn -> "batfoo" end)

    assert %SSHKit.Host{options: [key_cb: {SSHClientKeyAPI, cb_opts}]} =
             SSH.ssh_host_options(host)

    assert cb_opts[:passphrase] == "batfoo"
  end

  test "ssh_host_options/1 with public key and passphrase provider function reference", %{
    host_with_identity: host
  } do
    defmodule Bootleg.SSHTest.Foo do
      def baz, do: "foobaz"
    end

    host = Host.option(host, :passphrase_provider, {Bootleg.SSHTest.Foo, :baz})

    assert %SSHKit.Host{options: [key_cb: {SSHClientKeyAPI, cb_opts}]} =
             SSH.ssh_host_options(host)

    assert cb_opts[:passphrase] == "foobaz"
  end

  test "ssh_host_options/1 with public key and passphrase provider system command", %{
    host_with_identity: host
  } do
    host = Host.option(host, :passphrase_provider, {"echo", ["barfoo"]})

    assert %SSHKit.Host{options: [key_cb: {SSHClientKeyAPI, cb_opts}]} =
             SSH.ssh_host_options(host)

    assert cb_opts[:passphrase] == "barfoo"
  end

  test "ssh_opts/1 discards nil value options" do
    options = [port: nil, user: "foobar"]
    assert [user: "foobar"] == SSH.ssh_opts(options)
  end

  test "ssh_opts/1 does not allow arbitrary options" do
    options = [foobar: true, user: "foobar"]
    assert [user: "foobar"] == SSH.ssh_opts(options)
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

  test "ssh_options/0" do
    assert Enum.member?(SSH.ssh_options(), :quiet_mode)
  end
end
