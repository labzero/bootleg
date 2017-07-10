defmodule Bootleg.HostTest do
  use ExUnit.Case, async: true
  alias Bootleg.Host

  doctest Bootleg.Host

  setup do
    %{
      host: %Bootleg.Host{
        host: %SSHKit.Host{name: "127.0.0.1", options: [port: 22, user: "jsmith"]},
        options: []
      }
    }
  end

  test "init/3", %{host: host} do
    # ssh options are preserved in Bootleg.Host
    assert host == Host.init("127.0.0.1", [port: 22, user: "jsmith"], [])

    # role options are preserved in Bootleg.Host
    assert %Bootleg.Host{
      host: %SSHKit.Host{name: "127.0.0.1", options: [user: "ssh_user"]},
      options: [user: "scm_user"]
    } == Host.init("127.0.0.1", [user: "ssh_user"], [user: "scm_user"])
  end

  test "host_name/1", %{host: host} do
    assert "127.0.0.1" == Host.host_name(host)
  end
end
