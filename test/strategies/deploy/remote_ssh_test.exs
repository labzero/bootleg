defmodule Bootleg.Strategies.Deploy.RemoteSSHTest do
  use ExUnit.Case, async: false

  doctest Bootleg.Strategies.Deploy.RemoteSSH

  setup do
    deploy_setup =
      "
      set -e
      mkdir -p workspace
      "    
    %{
      deploy_setup: deploy_setup,
      config: %Bootleg.Config{
                app: "bootleg",
                version: "1.0.0",
                deploy: %Bootleg.DeployConfig{
                  identity: "identity",
                  workspace: "workspace",
                  host: "host",
                  user: "user"}
                }
    }
  end
  
  test "init", %{config: config, deploy_setup: deploy_setup} do      
    Bootleg.Strategies.Deploy.RemoteSSH.init(config)
    assert_received({Bootleg.SSH, :start})
    assert_received({Bootleg.SSH, :connect, ["host", "user", "identity"]})
    assert_received({Bootleg.SSH, :"run!", [:conn, ^deploy_setup, "."]})
  end

  test "deploy", %{config: config, deploy_setup: deploy_setup} do
    local_file = "#{File.cwd!}/releases/1.0.0.tar.gz"
    Bootleg.Strategies.Deploy.RemoteSSH.deploy(config)  
    assert_received({Bootleg.SSH, :start})
    assert_received({Bootleg.SSH, :connect, ["host", "user", "identity"]})
    assert_received({Bootleg.SSH, :"run!", [:conn, ^deploy_setup, "."]})
    assert_received({Bootleg.SSH, :upload, [:conn, ^local_file, "workspace/bootleg.tar.gz", []]})
    assert_received({Bootleg.SSH, :"run!", [:conn, "tar -zxvf workspace/bootleg.tar.gz", "workspace"]})    
  end
end