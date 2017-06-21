defmodule Bootleg.SSHTest do
  use ExUnit.Case, async: false
  alias Bootleg.{SSH, Role}
  alias SSHKit.{Context, Host}
  import ExUnit.CaptureIO

  doctest SSH

  setup do
    %{
      conn: %Context{
        pwd: ".",
        hosts: [
          %Host{name: "localhost.1", options: []},
          %Host{name: "localhost.2", options: []}
        ]
      },
      conn_opts: %Context{
        pwd: ".",
        hosts: [
          %Host{name: "localhost.1", options: [connect_timeout: 5000, user: "admin"]},
          %Host{name: "localhost.2", options: [connect_timeout: 5000, user: "admin"]}
        ]
      },
      role: %Role{
        hosts: ["localhost.1", "localhost.2"],
        name: :build,
        options: []
      }
    }
  end

  test "init/1 with Bootleg.Role", %{role: role} do
    capture_io(fn ->
      assert %Context{} = SSH.init(role), "Connection isn't a context"
    end)
  end

  test "init/1 with Role name atom", %{role: role_fixture} do
    use Bootleg.Config
    role :build, "build.labzero.com"

    capture_io(fn ->
      assert %Context{} = SSH.init(role_fixture.name)
    end)
  end

  test "init/2", %{conn_opts: conn} do
    capture_io(fn ->
      context = SSH.init(["localhost.1", "localhost.2"], "admin")
      assert conn == context
    end)
  end

  test "init/2 with identity" do
    capture_io(fn ->
      context = SSH.init(
        ["localhost.1", "localhost.2"],
        "admin",
        [identity: "test/fixtures/identity_rsa"])

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

  test "run!", %{conn: conn} do
    capture_io(fn ->
      assert [{:ok, _, 0, %{name: "localhost.1"}},
            {:ok, _, 0, %{name: "localhost.2"}}] = SSH.run!(conn, "hello")
    end)
  end

  test "upload", %{conn: conn} do
    capture_io(fn ->
      assert_raise RuntimeError, fn ->
        SSH.upload(conn, "nonexistant_file", "new_remote_file")
      end
    end)

    capture_io(fn ->
      assert :ok == SSH.upload(conn, "existing_local_file", "new_remote_file")
    end)
  end

  test "download", %{conn: conn} do
    capture_io(fn ->
      assert_raise RuntimeError, fn ->
        SSH.download(conn, "nonexistant_file", "new_local_file")
      end
    end)

    capture_io(fn ->
      assert :ok == SSH.download(conn, "existing_remote_file", "new_local_file")
    end)
  end
end
