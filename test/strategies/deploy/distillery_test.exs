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
    Distillery.init(config, project)
    assert_received({
      Bootleg.SSH,
      :init,
      ["host", "user", [identity: "identity", workspace: "workspace", create_workspace: true]]
    })
  end

  test "deploy", %{config: config, project: project} do
    local_file = "#{File.cwd!}/releases/1.0.0.tar.gz"
    assert capture_io(fn -> Distillery.deploy(config, project) end)
           == "Uploading release archive\nUnpacked release archive\n"
    assert_received({
      Bootleg.SSH,
      :init,
      ["host", "user", [identity: "identity", workspace: "workspace", create_workspace: true]]
    })
    assert_received({Bootleg.SSH, :upload, [:conn, ^local_file, "bootleg.tar.gz", []]})
    assert_received({Bootleg.SSH, :"run!", [:conn, "tar -zxvf bootleg.tar.gz"]})
  end
end
