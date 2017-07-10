defmodule Bootleg.SSHFunctionalTest do
  use Bootleg.FunctionalCase, async: true
  alias Bootleg.{Host, SSH}
  import ExUnit.CaptureIO

  @defaults [silently_accept_hosts: true]

  setup %{hosts: hosts} do
    %{
      bootleg_hosts: Enum.map(hosts, &hosts_from_docker(&1))
    }
  end

  def hosts_from_docker(options) do
    # options has some docker stuff we don't want to pass on
    ssh_options = [
      password: options.password,
      port: options.port,
      user: options.user
    ]
    Host.init(options.ip, ssh_options, [])
  end

  def filter_docker_props(options) do
    options
  end

  @tag boot: 1
  test "run!/2", %{bootleg_hosts: hosts} do
    capture_io(fn ->
      conn = SSH.init(hosts, @defaults)
      assert [{:ok, [stdout: "Linux\n"], 0, _}] = SSH.run!(conn, "uname")
    end)
  end

  @tag boot: 1
  test "init/3 raises an error if the host refuses the connection", %{bootleg_hosts: hosts} do
    capture_io(fn ->
      assert_raise SSHError, fn -> SSH.init(hosts, [port: 404]) end
    end)
  end

  @tag boot: 1
  test "run!/2 raises an error if the host refuses the connection", %{hosts: [host]} do
    capture_io(fn ->
      conn = SSHKit.context(SSHKit.host(host.ip, @defaults))
      assert_raise SSHError, fn -> SSH.run!(conn, "echo foo") end
    end)
  end
end
