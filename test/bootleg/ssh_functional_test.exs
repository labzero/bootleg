defmodule Bootleg.SSHFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.{Host, Role, SSH}
  alias SSHKit.Context, as: SSHKitContext
  alias SSHKit.Host, as: SSHKitHost
  import ExUnit.CaptureIO

  setup %{hosts: hosts} do
    %{
      role: %Role{
        hosts: Enum.map(hosts, &Host.init(&1.ip, docker_ssh_opts(&1), [])),
        name: :build,
        user: "blammo",
        options: [workspace: "some_workspace"]
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

  test "run!/2", %{role: role} do
    capture_io(fn ->
      conn = SSH.init(role.hosts)
      assert [{:ok, [stdout: "Linux\n"], 0, _}] = SSH.run!(conn, "uname")
    end)
  end

  test "init/3 raises an error if the host refuses the connection", %{hosts: hosts} do
    bootleg_hosts = Enum.map(hosts, &Host.init(&1.ip, [port: 404], []))
    capture_io(fn ->
      assert_raise SSHError, fn -> SSH.init(bootleg_hosts) end
    end)
  end

  @tag boot: 2
  test "init/2 with Bootleg.Role", %{role: role, hosts: hosts} do
    ip_1 = List.first(hosts).ip
    ip_2 = List.last(hosts).ip
    capture_io(fn ->
      assert %SSHKitContext{hosts: [
        %SSHKitHost{name: ^ip_1, options: options_1},
        %SSHKitHost{name: ^ip_2, options: options_2}
      ], path: "some_workspace"} = SSH.init(role), "Connection isn't a context"
      assert options_1[:port] != options_2[:port]
      assert options_1[:user] ==  "me"
    end)
  end

  test "init/2 with Role name atom", %{hosts: [host]} do
    use Bootleg.Config
    ip = host.ip
    role :build, host.ip, port: host.port, user: host.user, password: host.password,
      workspace: "/tmp/foo", silently_accept_hosts: true

    capture_io(fn ->
      assert %SSHKitContext{
        hosts: [%SSHKitHost{name: ^ip, options: options}],
        path: "/tmp/foo"} = SSH.init(:build)
      assert options[:user] == host.user
    end)
  end

  test "init/2 with Role name atom and identity", %{hosts: [host]} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config
    ip = host.ip
    role :build, ip, port: host.port, user: host.user,
      workspace: "/", silently_accept_hosts: true, identity: host.private_key_path

    capture_io(fn ->
      assert %SSHKitContext{
        hosts: [%SSHKitHost{name: ^ip, options: options}],
        path: "/"} = SSH.init(:build)
      assert options[:user] == host.user
      assert {SSHClientKeyAPI, key_details} = options[:key_cb]
      assert key_details[:identity_data] == host.private_key
    end)
  end

  test "run!/2 raises an error if the host refuses the connection", %{hosts: [host]} do
    capture_io(fn ->
      conn = SSHKit.context(SSHKit.host(host.ip))
      assert_raise SSHError, fn -> SSH.run!(conn, "echo foo") end
    end)
  end

  @tag boot: 2
  test "run!", %{role: role, hosts: [host_1, host_2]} do
    ip_1 = host_1.ip
    ip_2 = host_2.ip
    capture_io(fn ->
      conn = SSH.init(role)
      assert [{:ok, [stdout: "hello\n"], 0, %{name: ^ip_1}},
            {:ok, [stdout: "hello\n"], 0, %{name: ^ip_2}}] = SSH.run!(conn, "echo hello")
    end)
  end

  test "upload", %{role: role} do
    capture_io(fn ->
      conn = SSH.init(role)
      assert :ok == SSH.upload(conn, "test/fixtures/build.tar.gz", "new_remote_file")
      assert [{:ok, _, 0, _}] = SSH.run!(conn, "ls -la new_remote_file")
    end)
  end

  test "download", %{role: role} do
    capture_io(fn ->
      path = Temp.path!("scp-download")
      conn = SSH.init(role)
      assert :ok == SSH.download(conn, "/etc/hosts", path)
      assert File.regular?(path)
      File.rm!(path)
    end)
  end
end
