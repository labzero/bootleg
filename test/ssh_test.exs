defmodule Bootleg.SSHTest do
  use ExUnit.Case, async: false

  alias Bootleg.SSH
  alias SSHKit.Context

  doctest SSH

  setup do
    %{
      conn: %Context{hosts: [%{name: "localhost", options: []}]}
    }
  end

  test "connect", %{conn: conn} do
    assert %Context{} = conn, "Connection isn't a context"
  end

  test "run!", %{conn: conn} do
    assert [{:ok, _, 0}] = SSH.run!(conn, "ls", "/")
  end

  test "upload" do
    assert_raise RuntimeError, fn ->
      SSH.upload(:conn, "nonexistant_file", :new_remote_file)
    end

    assert :ok == SSH.upload(:conn, :existing_local_file, :new_remote_file)
  end

  test "download" do
    assert_raise RuntimeError, fn ->
      SSH.download(:conn, "nonexistant_file", :new_local_file)
    end

    assert :ok == SSH.download(:conn, :existing_remote_file, :new_local_file)
  end
end
