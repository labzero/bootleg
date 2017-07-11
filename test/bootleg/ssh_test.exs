defmodule Bootleg.SSHTest do
  use ExUnit.Case, async: false
  alias Bootleg.{SSH, Host, Role, Fixtures}
  alias SSHKit.Context
  alias SSHKit.Host, as: SSHKitHost
  import ExUnit.CaptureIO

  import Mock

  doctest SSH

  setup do
    %{
      conn: %Context{
        path: ".",
        hosts: [
          %Host{host: %SSHKitHost{name: "localhost.1", options: []}, options: []},
          %Host{host: %SSHKitHost{name: "localhost.2", options: []}, options: []}
        ]
      },
      conn_opts: %Context{
        path: ".",
        hosts: [
          %Host{
            host: %SSHKitHost{name: "localhost.1", options: [connect_timeout: 5000, user: "admin"]},
            options: []},
          %Host{
            host: %SSHKitHost{name: "localhost.2", options: [connect_timeout: 5000, user: "admin"]},
            options: []}
        ]
      },
      role: %Role{
        hosts: [
          %Host{host: %SSHKitHost{name: "localhost.1", options: []}, options: []},
          %Host{host: %SSHKitHost{name: "localhost.2", options: []}, options: []}
        ],
        name: :build,
        user: "sanejane",
        options: [workspace: "some workspace"]
      }
    }
  end

  @tag skip: "SSH: Migrate to functional tests"
  test "init/3 with identity" do
    capture_io(fn ->
      context = SSH.init(
        ["localhost.1", "localhost.2"],
        identity: Fixtures.identity_path)

      assert %Context{} = context

      assert {SSHKit.SSH.ClientKeyAPI, options} = context
      |> Map.get(:hosts)
      |> List.first
      |> Map.get(:options)
      |> Keyword.get(:key_cb)

      assert [:known_hosts_data, :identity_data, :known_hosts, :identity, :accept_hosts]
             = Keyword.keys(options)
    end)
  end

  @tag skip: "SSH: Migrate to functional tests"
  test "run!", %{conn: conn} do
    capture_io(fn ->
      assert [{:ok, _, 0, %{name: "localhost.1"}},
            {:ok, _, 0, %{name: "localhost.2"}}] = SSH.run!(conn, "hello")
    end)
  end

  @tag skip: "SSH: Migrate to functional tests"
  test "upload", %{conn: conn} do
    with_mock SSHKit, [], [upload: fn(_, _, _) -> [:ok] end] do
      capture_io(fn ->
        assert :ok == SSH.upload(conn, "existing_local_file", "new_remote_file")
      end)
    end
  end

  @tag skip: "SSH: Migrate to functional tests"
  test "download", %{conn: conn} do
    with_mock SSHKit, [], [download: fn(_, _, _) -> [:ok] end] do
      capture_io(fn ->
        assert :ok == SSH.download(conn, "existing_remote_file", "new_local_file")
      end)
    end
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
end
