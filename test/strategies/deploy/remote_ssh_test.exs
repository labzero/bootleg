defmodule Bootleg.Strategies.Deploy.RemoteSSHTest do
  use ExUnit.Case, async: false

  doctest Bootleg.Strategies.Deploy.RemoteSSH

  setup do  
    %{
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
  
  test "init", %{config: config} do      
    Bootleg.Strategies.Deploy.RemoteSSH.init(config)
    assert_received({Bootleg.SSH, :start})
    assert_received({Bootleg.SSH, :connect, ["host", "user", [identity: "identity", workspace: "workspace"]]})
  end

  test "deploy", %{config: config} do
    local_file = "#{File.cwd!}/releases/1.0.0.tar.gz"
    Bootleg.Strategies.Deploy.RemoteSSH.deploy(config)  
    assert_received({Bootleg.SSH, :start})
    assert_received({Bootleg.SSH, :connect, ["host", "user", [identity: "identity", workspace: "workspace"]]})
    assert_received({Bootleg.SSH, :upload, [:conn, ^local_file, "bootleg.tar.gz", []]})
    assert_received({Bootleg.SSH, :"run!", [:conn, "tar -zxvf bootleg.tar.gz"]})    
  end
end