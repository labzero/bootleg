defmodule Bootleg.Strategies.Administration.RemoteSSHTest do
  use ExUnit.Case, async: false

  doctest Bootleg.Strategies.Administration.RemoteSSH

  setup do
    %{
      config: 
        %Bootleg.Config{
          app: "bootleg",
          version: "1",
          administration: 
            %Bootleg.AdministrationConfig{
              identity: "identity",
              workspace: ".",
              host: "host",
              user: "user"
            }
        }
    }
  end
  
  test "init", %{config: config} do
    Bootleg.Strategies.Administration.RemoteSSH.init(config)
    assert_received({Bootleg.SSH, :start})
    assert_received({Bootleg.SSH, :connect, ["host", "user", [identity: "identity", workspace: "."]]})
  end

  test "start", %{config: %{app: app} = config} do
    Bootleg.Strategies.Administration.RemoteSSH.start(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg start"]})
  end

  test "stop", %{config: %{app: app} = config} do
    Bootleg.Strategies.Administration.RemoteSSH.stop(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg stop"]})
  end

  test "restart", %{config: %{app: app} = config} do
    Bootleg.Strategies.Administration.RemoteSSH.restart(:conn, config)
    assert_received({Bootleg.SSH, :"run!", [:conn, "bin/bootleg restart"]})
  end
end
