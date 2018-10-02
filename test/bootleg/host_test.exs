defmodule Bootleg.HostTest do
  use Bootleg.TestCase, async: true
  alias Bootleg.Host

  doctest Bootleg.Host

  setup do
    %{
      host: %Bootleg.Host{
        host: %SSHKit.Host{name: "127.0.0.1", options: []},
        options: [port: 22, user: "jsmith"]
      },
      bare_host: %Bootleg.Host{
        host: %SSHKit.Host{name: "localhost", options: []},
        options: []
      }
    }
  end

  test "init/2", %{host: host} do
    # ssh options are preserved in Bootleg.Host
    assert host == Host.init("127.0.0.1", port: 22, user: "jsmith")

    # role options are preserved in Bootleg.Host
    assert %Bootleg.Host{
             host: %SSHKit.Host{name: "127.0.0.1", options: []},
             options: [user: "scm_user"]
           } == Host.init("127.0.0.1", user: "scm_user")
  end

  test "host_name/1", %{host: host} do
    assert "127.0.0.1" == Host.host_name(host)
  end

  test "option/2", %{host: host} do
    assert nil == Host.option(host, :foo)
  end

  test "option/3", %{host: host} do
    assert %Bootleg.Host{
             host: %SSHKit.Host{name: "127.0.0.1", options: []},
             options: [foo: "bar", port: 22, user: "jsmith"]
           } == Host.option(host, :foo, "bar")
  end

  describe "combine_uniq/2" do
    test "prevents duplicates based on host name", %{bare_host: host} do
      assert [host] == Host.combine_uniq([host] ++ [host])
    end

    test "combines and overwrites host options", %{host: host1} do
      host2 = Host.option(host1, :foo, "bar")

      assert [
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "127.0.0.1", options: []},
                 options: [foo: "bar", port: 22, user: "jsmith"]
               }
             ] == Host.combine_uniq([host1] ++ [host2])
    end

    test "combines and overwrites ssh options", %{host: host1} do
      host2 = Host.option(host1, :user, "andy")

      assert [
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "127.0.0.1", options: []},
                 options: [port: 22, user: "andy"]
               }
             ] == Host.combine_uniq([host1] ++ [host2])
    end
  end
end
