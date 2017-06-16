defmodule Bootleg.Strategies.Deploy.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.Strategies.Deploy.Distillery
  import ExUnit.CaptureIO

  doctest Distillery

  setup do
    %{
      project: %Bootleg.Project{
        app_name: "bootleg",
        app_version: "1.0.0"},
      config: %Bootleg.Config{
                deploy: %Bootleg.Config.DeployConfig{
                  identity: "identity",
                  workspace: "workspace",
                  hosts: "host",
                  user: "user"}
                }
    }
  end

  test "init", %{config: config, project: project} do
    capture_io(fn -> assert %SSHKit.Context{} = Distillery.init(config, project) end)
  end

  test "deploy", %{config: config, project: project} do
    capture_io(fn -> assert :ok == Distillery.deploy(config, project) end)
  end
end
