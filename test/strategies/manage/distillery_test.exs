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
              user: "user",
              migration_module: "MyApp.Module"
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
        },
      bad_migrate_config:
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
      migration_function_config:
        %Bootleg.Config{
          app: "bootleg",
          version: "1.0.0",
          manage:
            %Bootleg.ManageConfig{
              identity: "identity",
              workspace: ".",
              hosts: "host",
              user: "user",
              migration_module: "MyApp.Module",
              migration_function: "a_function"
            }
        }
    }
  end

  test "init good", %{config: config} do
    Distillery.init(config)
    assert_received({Bootleg.SSH, :init, ["host", "user", [identity: "identity", workspace: "."]]})
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

  test "migrate with 'migration_function' uses the configured function", %{migration_function_config: config} do
    IO.puts config.manage.migration_module
    Distillery.migrate(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg rpcterms Elixir.MyApp.Module a_function 'bootleg.'"]})
  end

  test "migrate without 'migration_function' uses 'migrate/0'", %{config: config} do
    IO.puts config.manage.migration_module
    Distillery.migrate(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg rpcterms Elixir.MyApp.Module migrate 'bootleg.'"]})
  end

  test "migrate required configuration", %{bad_migrate_config: config} do
    assert catch_error(Distillery.migrate(:conn, config)) == %RuntimeError{message: "Error: This strategy requires \"migration_module\" to be configured"}
  end
end
