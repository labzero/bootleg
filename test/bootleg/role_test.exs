defmodule Bootleg.RoleTest do
  use ExUnit.Case, async: true
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
            host: %SSHKitHost{name: "alpha", options: [port: 22, user: "johnny"]},
            options: []
          },
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
          host: %SSHKitHost{name: "alpha", options: [port: 22, user: "johnny"]},
          options: []
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
          host: %SSHKitHost{name: "alpha", options: [port: 22]},
          options: [primary: true]
        }
      ]

      new_role = Role.combine_hosts(role, hosts)

      assert [
        %Host{
          host: %SSHKitHost{name: "alpha", options: [user: "johnny", port: 22]},
          options: [primary: true]
        }
      ] == new_role.hosts
    end

    test "combines and preserves multiple hosts", %{role: role} do
      hosts = [
        %Host{
          host: %SSHKitHost{name: "bravo", options: [user: "first", port: 2222]},
          options: [primary: true]
        },
        %Host{
          host: %SSHKitHost{name: "bravo", options: [user: "second", port: 2222]},
          options: []
        },
      ]

      new_role = Role.combine_hosts(role, hosts)

      assert [
        %Host{
          host: %SSHKitHost{name: "alpha", options: [port: 22, user: "johnny"]},
          options: []
        },
        %Host{
          host: %SSHKitHost{name: "bravo", options: [user: "second", port: 2222]},
          options: [primary: true]
        },
      ] == new_role.hosts
    end
  end
end
