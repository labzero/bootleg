defmodule Bootleg.Strategies.Manage.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.Strategies.Manage.Distillery

  doctest Distillery

  setup do
    %{
      config:
        %Bootleg.Config{
          app: "bootleg",
          version: "1.0.0",
          manage:
            %Bootleg.ManageConfig{
              identity: "identity",
              workspace: ".",
              hosts: "host",
              user: "user"
            }
        },
      bad_config:
        %Bootleg.Config{
          app: "Funky Monkey",
          version: "1.0.0",
          manage:
            %Bootleg.ManageConfig{
              identity: nil,
              "workspace": "what",
              hosts: nil
            }
          }
    }
  end

  test "init good", %{config: config} do
    Distillery.init(config)
    assert_received({Bootleg.SSH, :start})
    assert_received({Bootleg.SSH, :connect, ["host", "user", [identity: "identity", workspace: "."]]})
  end

  test "init bad", %{bad_config: config} do
    assert_raise RuntimeError, ~r/This strategy requires "hosts", "user" to be configured/, fn ->
      Distillery.init(config)
    end
  end

  test "start", %{config: config} do
    Distillery.start(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg start"]})
  end

  test "stop", %{config: config} do
    Distillery.stop(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg stop"]})
  end

  test "restart", %{config: config} do
    Distillery.restart(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg restart"]})
  end

  test "ping", %{config: config} do
    Distillery.ping(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg ping"]})
  end
end
