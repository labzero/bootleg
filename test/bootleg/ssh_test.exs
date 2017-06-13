defmodule Bootleg.SSHTest do
  use ExUnit.Case, async: false
  alias Bootleg.{SSH, Role}
  alias SSHKit.{Context, Host}

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
          %Host{name: "localhost.1", options: [user: "admin"]},
          %Host{name: "localhost.2", options: [user: "admin"]}
        ]
      },
      role: %Role{
        hosts: ["localhost.1", "localhost.2"],
        name: "admin",
        options: []
      }
    }
  end

  test "init/1", %{role: role} do
    assert %Context{} = SSH.init(role), "Connection isn't a context"
  end

  test "init/2", %{conn_opts: conn} do
    context = SSH.init(["localhost.1", "localhost.2"], "admin")
    assert conn == context
  end

  test "run!", %{conn: conn} do
    assert [{:ok, _, 0, %{name: "localhost.1"}},
            {:ok, _, 0, %{name: "localhost.2"}}] = SSH.run!(conn, "hello")
  end

  test "upload", %{conn: conn} do
    assert_raise RuntimeError, fn ->
      SSH.upload(conn, "nonexistant_file", "new_remote_file")
    end

    assert :ok == SSH.upload(conn, "existing_local_file", "new_remote_file")
  end

  test "download", %{conn: conn} do
    assert_raise RuntimeError, fn ->
      SSH.download(conn, "nonexistant_file", "new_local_file")
    end

    assert :ok == SSH.download(conn, "existing_remote_file", "new_local_file")
  end
end
