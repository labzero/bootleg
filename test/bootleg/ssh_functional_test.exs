defmodule Bootleg.SSHFunctionalTest do
  use Bootleg.FunctionalCase, async: true
  alias Bootleg.{Host, Role, SSH, Fixtures}
  alias SSHKit.Context, as: SSHKitContext
  alias SSHKit.Host, as: SSHKitHost
  import ExUnit.CaptureIO

  setup %{hosts: hosts} do
    %{
      role: %Role{
        hosts: Enum.map(hosts, &Host.init(&1.ip, docker_ssh_opts(&1), [])),
        name: :build,
        user: "blammo",
        options: [workspace: "some workspace"]
      }
    }
  end

  def docker_ssh_opts(host) do
    [
      password: host.password,
      port: host.port,
      user: host.user,
      silently_accept_hosts: true
    ]
  end

  @tag boot: 1
  test "run!/2", %{role: role} do
    capture_io(fn ->
      conn = SSH.init(role.hosts)
      assert [{:ok, [stdout: "Linux\n"], 0, _}] = SSH.run!(conn, "uname")
    end)
  end

  @tag boot: 1
  test "init/3 raises an error if the host refuses the connection", %{hosts: hosts} do
    bootleg_hosts = Enum.map(hosts, &Host.init(&1.ip, [port: 404], []))
    capture_io(fn ->
      assert_raise SSHError, fn -> SSH.init(bootleg_hosts) end
    end)
  end

  @tag boot: 2
  test "init/2 with Bootleg.Role", %{role: role} do
    capture_io(fn ->
      assert %SSHKitContext{hosts: [
        %SSHKitHost{name: "127.0.0.1", options: options_1},
        %SSHKitHost{name: "127.0.0.1", options: options_2}
      ], path: "some workspace"} = SSH.init(role), "Connection isn't a context"
      assert options_1[:port] != options_2[:port]
      assert options_1[:user] ==  "me"
    end)
  end

  @tag boot: 1
  test "init/2 with Role name atom", %{hosts: [host]} do
    use Bootleg.Config
    role :build, host.ip, port: host.port, user: host.user, password: host.password,
      workspace: "/tmp/foo", silently_accept_hosts: true

    capture_io(fn ->
      assert %SSHKitContext{
        hosts: [%SSHKitHost{name: "127.0.0.1", options: options}],
        path: "/tmp/foo"} = SSH.init(:build)
      assert options[:user] == host.user
    end)
  end

  @tag skip: "identity file needs to be added to docker"
  test "init/2 with Role name atom and identity", %{hosts: [host]} do
    use Bootleg.{Config}
    role :build, host.ip, port: host.port, user: host.user,
      workspace: "/", silently_accept_hosts: true, identity: Fixtures.identity_path

    capture_io(fn ->
      assert %SSHKitContext{
        hosts: [%SSHKitHost{name: "build.labzero.com", options: options}],
        path: "some path"} = SSH.init(:build)
      assert options[:user] == host.user
      assert options[:identity] == Fixtures.identity_path
      assert {SSHKit.SSH.ClientKeyAPI, _} = options[:key_cb]
    end)
  end

  @tag boot: 1
  test "run!/2 raises an error if the host refuses the connection", %{hosts: [host]} do
    capture_io(fn ->
      conn = SSHKit.context(SSHKit.host(host.ip))
      assert_raise SSHError, fn -> SSH.run!(conn, "echo foo") end
    end)
  end
end
