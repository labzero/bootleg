defmodule Bootleg.Strategies.Manage.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.{Strategies.Manage.Distillery, Fixtures}
  import ExUnit.CaptureIO

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
              identity: Fixtures.identity_path(),
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
              identity: Fixtures.identity_path(),
              workspace: ".",
              hosts: "host",
              user: "user"
            }
        },
      migration_function_config:
        %Bootleg.Config{
          manage:
            %Bootleg.Config.ManageConfig{
              identity: Fixtures.identity_path(),
              workspace: ".",
              hosts: "host",
              user: "user",
              migration_module: "MyApp.Module",
              migration_function: "a_function"
            }
        },
      conn:
        %SSHKit.Context{
          hosts: [%SSHKit.Host{name: "host.1"}]
        }
    }
  end

  @tag skip: "Migrate to functional test"
  test "init good", %{config: config, project: project} do
    capture_io(fn -> assert %SSHKit.Context{} = Distillery.init(config, project) end)
  end

  @tag skip: "Migrate to functional test"
  test "init bad", %{bad_config: config, project: project} do
    assert_raise RuntimeError, ~r/This strategy requires "hosts", "user" to be configured/, fn ->
      Distillery.init(config, project)
    end
  end

  @tag skip: "Migrate to functional test"
  test "start", %{conn: conn, config: config, project: project} do
    capture_io(fn -> assert {:ok, %SSHKit.Context{}} = Distillery.start(conn, config, project) end)
  end

  @tag skip: "Migrate to functional test"
  test "stop", %{conn: conn, config: config, project: project} do
    capture_io(fn -> assert {:ok, %SSHKit.Context{}} = Distillery.stop(conn, config, project) end)
  end

  @tag skip: "Migrate to functional test"
  test "restart", %{conn: conn, config: config, project: project} do
    capture_io(fn ->
      assert {:ok, %SSHKit.Context{}} = Distillery.restart(conn, config, project)
    end)
  end

  @tag skip: "Migrate to functional test"
  test "ping", %{conn: conn, config: config, project: project} do
    capture_io(fn ->
      assert {:ok, %SSHKit.Context{}} = Distillery.ping(conn, config, project)
    end)
  end

  @tag skip: "Migrate to functional test"
  test "migrate with 'migration_function' uses the configured function",
       %{conn: conn, migration_function_config: config, project: project} do
    capture_io(fn ->
      assert :ok = Distillery.migrate(conn, config, project)
    end)
  end

  @tag skip: "Migrate to functional test"
  test "migrate without 'migration_function' uses 'migrate/0'",
       %{conn: conn, config: config, project: project} do
    capture_io(fn ->
      assert :ok = Distillery.migrate(conn, config, project)
    end)
  end

  @tag skip: "Migrate to functional test"
  test "migrate required configuration",
       %{conn: conn, bad_migrate_config: config, project: project} do
    assert catch_error(Distillery.migrate(conn, config, project))
      == %RuntimeError{message: "Error: This strategy requires \"migration_module\" to be configured"}
  end
end
