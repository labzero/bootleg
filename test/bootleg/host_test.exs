defmodule Bootleg.HostTest do
  use Bootleg.TestCase, async: true
  alias Bootleg.Host

  doctest Bootleg.Host

  setup do
    %{
      host: %Bootleg.Host{
        host: %SSHKit.Host{name: "127.0.0.1", options: [port: 22, user: "jsmith"]},
        options: []
      },
      bare_host: %Bootleg.Host{
        host: %SSHKit.Host{name: "localhost", options: []},
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
           } == Host.init("127.0.0.1", [user: "ssh_user"], user: "scm_user")
  end

  test "host_name/1", %{host: host} do
    assert "127.0.0.1" == Host.host_name(host)
  end

  test "option/2", %{host: host} do
    assert nil == Host.option(host, :foo)
  end

  test "option/3", %{host: host} do
    assert %Bootleg.Host{
             host: %SSHKit.Host{name: "127.0.0.1", options: [port: 22, user: "jsmith"]},
             options: [foo: "bar"]
           } == Host.option(host, :foo, "bar")
  end

  test "ssh_option/2", %{host: host} do
    assert 22 == Host.ssh_option(host, :port)
    assert "jsmith" == Host.ssh_option(host, :user)
  end

  test "ssh_option/3", %{host: host} do
    assert %Bootleg.Host{
             host: %SSHKit.Host{name: "127.0.0.1", options: [port: 2222, user: "jsmith"]},
             options: []
           } == Host.ssh_option(host, :port, 2222)
  end

  describe "combine_uniq/2" do
    test "prevents duplicates based on host name", %{bare_host: host} do
      assert [host] == Host.combine_uniq([host] ++ [host])
    end

    test "combines and overwrites host options", %{host: host1} do
      host2 = Host.option(host1, :foo, "bar")

      assert [
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "127.0.0.1", options: [port: 22, user: "jsmith"]},
                 options: [foo: "bar"]
               }
             ] == Host.combine_uniq([host1] ++ [host2])
    end

    test "combines and overwrites ssh options", %{host: host1} do
      host2 = Host.ssh_option(host1, :user, "andy")

      assert [
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "127.0.0.1", options: [port: 22, user: "andy"]},
                 options: []
               }
             ] == Host.combine_uniq([host1] ++ [host2])
    end
  end
end
