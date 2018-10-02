defmodule Bootleg.RoleTest do
  use Bootleg.TestCase, async: true
  alias Bootleg.{Host, Role}
  alias SSHKit.Host, as: SSHKitHost

  doctest Bootleg.Role

  setup do
    %{
      role: %Bootleg.Role{
        name: :app,
        user: "deploy",
        options: [],
        hosts: [
          %Host{
            host: %SSHKitHost{name: "alpha", options: []},
            options: [port: 22, user: "johnny"]
          }
        ]
      }
    }
  end

  describe "combine_hosts/2" do
    test "appends hosts", %{role: role} do
      hosts = [
        %Host{
          host: %SSHKitHost{name: "bravo", options: []},
          options: []
        }
      ]

      new_role = Role.combine_hosts(role, hosts)

      assert [
               %Host{
                 host: %SSHKitHost{name: "alpha", options: []},
                 options: [port: 22, user: "johnny"]
               },
               %Host{
                 host: %SSHKitHost{name: "bravo", options: []},
                 options: []
               }
             ] == new_role.hosts
    end

    test "combines previous host options for the same host name and port", %{role: role} do
      hosts = [
        %Host{
          host: %SSHKitHost{name: "alpha", options: []},
          options: [primary: true, port: 22]
        }
      ]

      new_role = Role.combine_hosts(role, hosts)

      assert [
               %Host{
                 host: %SSHKitHost{name: "alpha", options: []},
                 options: [user: "johnny", primary: true, port: 22]
               }
             ] == new_role.hosts
    end

    test "combines and preserves multiple hosts", %{role: role} do
      hosts = [
        %Host{
          host: %SSHKitHost{name: "bravo", options: []},
          options: [primary: true, user: "first", port: 2222]
        },
        %Host{
          host: %SSHKitHost{name: "bravo", options: []},
          options: [user: "second", port: 2222]
        }
      ]

      new_role = Role.combine_hosts(role, hosts)

      assert [
               %Host{
                 host: %SSHKitHost{name: "alpha", options: []},
                 options: [port: 22, user: "johnny"]
               },
               %Host{
                 host: %SSHKitHost{name: "bravo", options: []},
                 options: [primary: true, user: "second", port: 2222]
               }
             ] == new_role.hosts
    end
  end
end
