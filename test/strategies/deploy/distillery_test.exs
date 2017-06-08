defmodule Bootleg.Strategies.Deploy.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.Strategies.Deploy.Distillery

  doctest Distillery

  setup do
    %{
      config: %Bootleg.Config{
                app: "bootleg",
                version: "1.0.0",
                deploy: %Bootleg.Config.DeployConfig{
                  identity: "identity",
                  workspace: "workspace",
                  hosts: "host",
                  user: "user"}
                }
    }
  end

  test "init", %{config: config} do
    Distillery.init(config)
    assert_received({
      Bootleg.SSH,
      :init,
      ["host", "user", [identity: "identity", workspace: "workspace", create_workspace: true]]
    })
  end

  test "deploy", %{config: config} do
    local_file = "#{File.cwd!}/releases/1.0.0.tar.gz"
    Distillery.deploy(config)
    assert_received({
      Bootleg.SSH,
      :init,
      ["host", "user", [identity: "identity", workspace: "workspace", create_workspace: true]]
    })
    assert_received({Bootleg.SSH, :upload, [:conn, ^local_file, "bootleg.tar.gz", []]})
    assert_received({Bootleg.SSH, :"run!", [:conn, "tar -zxvf bootleg.tar.gz"]})
  end
end
