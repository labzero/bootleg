defmodule Bootleg.Strategies.Deploy.RemoteSSHTest do
  use ExUnit.Case, async: false
  alias Bootleg.Strategies.Deploy.RemoteSSH

  doctest RemoteSSH

  setup do
    %{
      config: %Bootleg.Config{
                app: "bootleg",
                version: "1.0.0",
                deploy: %Bootleg.DeployConfig{
                  identity: "identity",
                  workspace: "workspace",
                  hosts: "host",
                  user: "user"}
                }
    }
  end

  test "init", %{config: config} do
    RemoteSSH.init(config)
    assert_received({Bootleg.SSH, :start})
    assert_received({Bootleg.SSH, :connect, ["host", "user", [identity: "identity", workspace: "workspace"]]})
  end

  test "deploy", %{config: config} do
    local_file = "#{File.cwd!}/releases/1.0.0.tar.gz"
    RemoteSSH.deploy(config)
    assert_received({Bootleg.SSH, :start})
    assert_received({Bootleg.SSH, :connect, ["host", "user", [identity: "identity", workspace: "workspace"]]})
    assert_received({Bootleg.SSH, :upload, [:conn, ^local_file, "bootleg.tar.gz", []]})
    assert_received({Bootleg.SSH, :"run!", [:conn, "tar -zxvf bootleg.tar.gz"]})
  end
end
