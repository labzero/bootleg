defmodule Bootleg.Strategies.Manage.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.{Strategies.Manage.Distillery, Fixtures}
  import ExUnit.CaptureIO

  doctest Distillery

  setup do
    %{
      config:
        %Bootleg.Config{
          manage:
            %Bootleg.Config.ManageConfig{
              identity: Fixtures.identity_path(),
              workspace: ".",
              hosts: "host",
              user: "user",
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
      conn:
        %SSHKit.Context{
          hosts: [%SSHKit.Host{name: "host.1"}]
        }
    }
  end

  @tag skip: "Migrate to functional test"
  test "init good", %{config: config} do
    capture_io(fn -> assert %SSHKit.Context{} = Distillery.init(config) end)
  end

  @tag skip: "Migrate to functional test"
  test "init bad", %{bad_config: config} do
    assert_raise RuntimeError, ~r/This strategy requires "hosts", "user" to be configured/, fn ->
      Distillery.init(config)
    end
  end

  @tag skip: "Migrate to functional test"
  test "start", %{conn: conn, config: config} do
    capture_io(fn -> assert {:ok, %SSHKit.Context{}} = Distillery.start(conn, config) end)
  end

  @tag skip: "Migrate to functional test"
  test "stop", %{conn: conn, config: config} do
    capture_io(fn -> assert {:ok, %SSHKit.Context{}} = Distillery.stop(conn, config) end)
  end

  @tag skip: "Migrate to functional test"
  test "restart", %{conn: conn, config: config} do
    capture_io(fn ->
      assert {:ok, %SSHKit.Context{}} = Distillery.restart(conn, config)
    end)
  end

  @tag skip: "Migrate to functional test"
  test "ping", %{conn: conn, config: config} do
    capture_io(fn ->
      assert {:ok, %SSHKit.Context{}} = Distillery.ping(conn, config)
    end)
  end
end
