defmodule Bootleg.Strategies.Manage.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.Strategies.Manage.Distillery

  doctest Distillery

  setup do
    %{
      project: %Bootleg.Project{
        app_name: "bootleg",
        app_version: "1.0.0"},
      config:
        %Bootleg.Config{
          manage:
            %Bootleg.Config.ManageConfig{
              identity: "identity",
              workspace: ".",
              hosts: "host",
              user: "user",
              migration_module: "MyApp.Module"
            }
        },
      bad_config:
        %Bootleg.Config{
          manage:
            %Bootleg.Config.ManageConfig{
              identity: nil,
              "workspace": "what",
              hosts: nil
            }
        },
      bad_migrate_config:
        %Bootleg.Config{
          manage:
            %Bootleg.Config.ManageConfig{
              identity: "identity",
              workspace: ".",
              hosts: "host",
              user: "user"
            }
        },
      migration_function_config:
        %Bootleg.Config{
          manage:
            %Bootleg.Config.ManageConfig{
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

  test "init good", %{config: config, project: project} do
    Distillery.init(config, project)
    assert_received({Bootleg.SSH, :init, ["host", "user", [identity: "identity", workspace: "."]]})
  end

  test "init bad", %{bad_config: config, project: project} do
    assert_raise RuntimeError, ~r/This strategy requires "hosts", "user" to be configured/, fn ->
      Distillery.init(config, project)
    end
  end

  test "start", %{config: config, project: project} do
    Distillery.start(:conn, config, project)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg start"]})
  end

  test "stop", %{config: config, project: project} do
    Distillery.stop(:conn, config, project)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg stop"]})
  end

  test "restart", %{config: config, project: project} do
    Distillery.restart(:conn, config, project)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg restart"]})
  end

  test "ping", %{config: config, project: project} do
    Distillery.ping(:conn, config, project)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg ping"]})
  end

  test "migrate with 'migration_function' uses the configured function", %{migration_function_config: config, project: project} do
    IO.puts config.manage.migration_module
    Distillery.migrate(:conn, config, project)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg rpcterms Elixir.MyApp.Module a_function 'bootleg.'"]})
  end

  test "migrate without 'migration_function' uses 'migrate/0'", %{config: config, project: project} do
    IO.puts config.manage.migration_module
    Distillery.migrate(:conn, config, project)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg rpcterms Elixir.MyApp.Module migrate 'bootleg.'"]})
  end

  test "migrate required configuration", %{bad_migrate_config: config, project: project} do
    assert catch_error(Distillery.migrate(:conn, config, project)) == %RuntimeError{message: "Error: This strategy requires \"migration_module\" to be configured"}
  end
end
