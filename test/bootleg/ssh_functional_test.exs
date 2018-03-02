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
      },
      role_env: %Role{
        hosts: Enum.map(hosts, &Host.init(&1.ip, docker_ssh_opts(&1), [])),
        name: :build,
        user: "blammo",
        options: [workspace: "some_workspace", env: %{"BOOTLEG_ENV_TEST" => "ENV_TEST_VALUE"}]
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

  @tag :smoke
  test "run!/2", %{role: role} do
    capture_io(fn ->
      conn = SSH.init(role.hosts)
      assert [{:ok, [stdout: "Linux\n"], 0, _}] = SSH.run!(conn, "uname")
    end)
  end

  test "run!/2 with role env", %{role_env: role} do
    capture_io(fn ->
      conn = SSH.init(role)

      assert [{:ok, [stdout: "ENV_TEST_VALUE\n"], 0, _}] =
               SSH.run!(conn, "echo $BOOTLEG_ENV_TEST")
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
      assert %SSHKitContext{
               hosts: [
                 %SSHKitHost{name: ^ip_1, options: options_1},
                 %SSHKitHost{name: ^ip_2, options: options_2}
               ],
               path: "some_workspace"
             } = SSH.init(role),
             "Connection isn't a context"

      assert options_1[:port] != options_2[:port]
      assert options_1[:user] == "me"
    end)
  end

  test "init/2 with Role name atom", %{hosts: [host]} do
    use Bootleg.DSL
    ip = host.ip

    role(
      :build,
      host.ip,
      port: host.port,
      user: host.user,
      password: host.password,
      workspace: "/tmp/foo",
      silently_accept_hosts: true
    )

    capture_io(fn ->
      assert %SSHKitContext{hosts: [%SSHKitHost{name: ^ip, options: options}], path: "/tmp/foo"} =
               SSH.init(:build)

      assert options[:user] == host.user
    end)
  end

  test "init/2 with Role name atom and identity", %{hosts: [host]} do
    use Bootleg.DSL
    ip = host.ip

    role(
      :build,
      ip,
      port: host.port,
      user: host.user,
      workspace: "/",
      silently_accept_hosts: true,
      identity: host.private_key_path
    )

    capture_io(fn ->
      assert %SSHKitContext{hosts: [%SSHKitHost{name: ^ip, options: options}], path: "/"} =
               SSH.init(:build)

      assert options[:user] == host.user
      assert {SSHClientKeyAPI, key_details} = options[:key_cb]
      assert key_details[:identity_data] == host.private_key
    end)
  end

  @tag boot: 2
  test "init/3 host filtering for roles", %{hosts: [host_1, host_2]} do
    use Bootleg.DSL

    ip_1 = host_1.ip
    ip_2 = host_2.ip

    role(
      :build,
      ip_1,
      port: host_1.port,
      user: host_1.user,
      foo: :car,
      workspace: "/",
      silently_accept_hosts: true,
      identity: host_1.private_key_path
    )

    role(
      :build,
      ip_2,
      port: host_2.port,
      user: host_2.user,
      foo: :bar,
      workspace: "/",
      silently_accept_hosts: true,
      identity: host_2.private_key_path
    )

    capture_io(fn ->
      assert %SSHKitContext{hosts: [%SSHKitHost{name: ^ip_2}]} = SSH.init(:build, [], foo: :bar)
      assert %SSHKitContext{hosts: [%SSHKitHost{name: ^ip_1}]} = SSH.init(:build, [], foo: :car)
    end)
  end

  test "init/3 working directory option", %{hosts: [host]} do
    use Bootleg.DSL

    role(
      :valid_workspace,
      host.ip,
      port: host.port,
      user: host.user,
      workspace: "./woo/bar",
      silently_accept_hosts: true,
      identity: host.private_key_path
    )

    role(
      :bad_workspace,
      host.ip,
      port: host.port,
      user: host.user,
      workspace: "/woo/bar",
      silently_accept_hosts: true,
      identity: host.private_key_path
    )

    capture_io(fn ->
      assert %SSHKitContext{path: "/foo"} = SSH.init(:valid_workspace, cd: "/foo")
      assert %SSHKitContext{path: "./woo/bar/foo"} = SSH.init(:valid_workspace, cd: "foo")
      assert %SSHKitContext{path: "./woo/bar"} = SSH.init(:valid_workspace, cd: nil)
      assert_raise SSHError, fn -> SSH.init(:bad_workspace, cd: "/foo") end
      assert_raise SSHError, fn -> SSH.init(:bad_workspace, cd: "foo") end
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

      assert [
               {:ok, [stdout: "hello\n"], 0, %{name: ^ip_1}},
               {:ok, [stdout: "hello\n"], 0, %{name: ^ip_2}}
             ] = SSH.run!(conn, "echo hello")
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

  test "returns output in whole line increments", %{hosts: [host]} do
    use Bootleg.DSL

    role(
      :node,
      host.ip,
      port: host.port,
      user: host.user,
      workspace: "/",
      silently_accept_hosts: true,
      identity: host.private_key_path
    )

    n = 100_000
    digest = :crypto.hash_init(:sha256)
    checksum = :crypto.hash(:sha256, Enum.join(Enum.map(1..n, fn i -> "#{i}\n" end)))

    capture_io(fn ->
      [{:ok, data, 0, _}] = remote(:node, "seq 1 #{n}")

      {chunk_sums, digest} =
        Enum.map_reduce(data, digest, fn {_, bytes}, digest ->
          # ensure the chunk is well formed
          assert :binary.last(bytes) == 0x0A
          digest = :crypto.hash_update(digest, bytes)
          {lines, _} = String.split_at(bytes, -1)
          {Enum.sum(Enum.map(String.split(lines, "\n"), &String.to_integer/1)), digest}
        end)

      # ensure no bytes got shifted
      assert Enum.sum(chunk_sums) == n * (n + 1) / 2
      # ensure no bytes got lost
      assert :crypto.hash_final(digest) == checksum
    end)
  end

  test "set bootleg env", %{hosts: [host]} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.DSL

    config :env, :foo

    role(
      :app,
      host.ip,
      port: host.port,
      user: host.user,
      workspace: "/",
      silently_accept_hosts: true,
      identity: host.private_key_path
    )

    capture_io(fn ->
      assert [{:ok, [stdout: "foo"], 0, _}] = remote(:app, "echo -n ${BOOTLEG_ENV}")
    end)
  end

  test "replace os vars", %{hosts: [host]} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.DSL

    role(
      :default_replace,
      host.ip,
      port: host.port,
      user: host.user,
      workspace: "/",
      silently_accept_hosts: true,
      identity: host.private_key_path
    )

    role(
      :no_replace,
      host.ip,
      port: host.port,
      user: host.user,
      workspace: "/",
      silently_accept_hosts: true,
      identity: host.private_key_path,
      replace_os_vars: false
    )

    capture_io(fn ->
      assert [{:ok, [stdout: "true"], 0, _}] =
               remote(:default_replace, "echo -n ${REPLACE_OS_VARS}")

      assert [{:ok, [], 0, _}] = remote(:no_replace, "echo -n ${REPLACE_OS_VARS}")
    end)
  end
end
