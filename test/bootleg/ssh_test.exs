defmodule Bootleg.SSHTest do
  use ExUnit.Case, async: false
  alias Bootleg.{SSH, Role, Fixtures}
  alias SSHKit.{Context, Host}
  import ExUnit.CaptureIO

  import Mock

  doctest SSH

  setup do
    %{
      conn: %Context{
        path: ".",
        hosts: [
          %Host{name: "localhost.1", options: []},
          %Host{name: "localhost.2", options: []}
        ]
      },
      conn_opts: %Context{
        path: ".",
        hosts: [
          %Host{name: "localhost.1", options: [connect_timeout: 5000, user: "admin"]},
          %Host{name: "localhost.2", options: [connect_timeout: 5000, user: "admin"]}
        ]
      },
      role: %Role{
        hosts: ["localhost.1", "localhost.2"],
        name: :build,
        user: "sanejane",
        options: [workspace: "some workspace"]
      }
    }
  end

  @tag skip: "SSH: Migrate to functional tests"
  test "init/2 with Bootleg.Role", %{role: role} do
    capture_io(fn ->
      assert %Context{hosts: [
        %Host{name: "localhost.1", options: options_1},
        %Host{name: "localhost.2", options: options_2}
      ], path: "some workspace"} = SSH.init(role), "Connection isn't a context"
      assert options_1 == options_2
      assert options_1[:user] ==  "sanejane"
    end)
  end

  @tag skip: "SSH: Migrate to functional tests"
  test "init/2 with Role name atom" do
    use Bootleg.Config
    role :build, "build.labzero.com", workspace: "some path", user: "sanejane", identity: Fixtures.identity_path

    capture_io(fn ->
      assert %Context{hosts: [%Host{name: "build.labzero.com", options: options}], path: "some path"} = SSH.init(:build)
      assert options[:user] == "sanejane"
      assert options[:identity] == Fixtures.identity_path
      assert {SSHKit.SSH.ClientKeyAPI, _} = options[:key_cb]
    end)
  end

  @tag skip: "SSH: Migrate to functional tests"
  test "init/2 with options", %{role: role} do
    capture_io(fn ->
      assert %Context{path: "some other workspace"}
        = SSH.init(role, workspace: "some other workspace"), "Workspace isn't overridden"
      assert %Context{hosts: [%Host{options: options_1}, %Host{options: options_2}]}
        = SSH.init(role, user: "slimjim")
      assert options_1 == options_2
      assert options_1[:user] == "slimjim", "User isn't overridden"
    end)
  end

  @tag skip: "SSH: Migrate to functional tests"
  test "init/3", %{conn: conn} do
    capture_io(fn ->
      context = SSH.init(["localhost.1", "localhost.2"])
      assert conn == context
    end)
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
    capture_io(fn ->
      assert_raise SSHError, fn -> SSH.init("bad-host-name") end
    end)
  end

  test "run!/2 raises an error if the host is not found" do
    capture_io(fn ->
      conn = SSHKit.context(SSHKit.host("bad-host-name"))
      assert_raise SSHError, fn -> SSH.run!(conn, "echo foo") end
    end)
  end
end
