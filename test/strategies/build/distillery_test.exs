defmodule Bootleg.Strategies.Build.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.Strategies.Build.Distillery
  import ExUnit.CaptureIO

  doctest Distillery

  setup do
    %{
      project: %Bootleg.Project{
        app_name: "bootleg",
        app_version: "1.0.0"},

      config: %Bootleg.Config{
                build: %Bootleg.Config.BuildConfig{
                  strategy: Bootleg.Strategies.Build.Distillery,
                  identity: "identity",
                  workspace: "workspace",
                  host: "host",
                  user: "user",
                  mix_env: "test",
                  refspec: "master",
                  push_options: "-f"}
                }
    }
  end

  test "init", %{config: config, project: project} do
    Distillery.init(config, project)
    assert_received({
      Bootleg.SSH,
      :init,
      ["host", [identity: "identity", workspace: "workspace", user: "user", create_workspace: true]]
    })
    assert_received({Bootleg.SSH, :"run!", [:conn, "git config receive.denyCurrentBranch ignore"]})
  end

  test "build", %{config: config, project: project} do
    local_file = "#{File.cwd!}/releases/build.tar.gz"
    capture_io(fn -> Distillery.build(config, project) end)
    assert_received({
      Bootleg.SSH,
      :init,
      ["host", [identity: "identity", workspace: "workspace", user: "user", create_workspace: true]]
    })
    assert_received({Bootleg.SSH, :"run!", [:conn, "git config receive.denyCurrentBranch ignore"]})
    assert_received({Bootleg.Git, :push,  [["--tags", "-f", "user@host:workspace", "master"], [env: [{"GIT_SSH_COMMAND", "ssh -i 'identity'"}]]]})
    assert_received({Bootleg.SSH, :"run!", [:conn, "git reset --hard master"]})
    assert_received({Bootleg.SSH, :run!, [:conn, ["MIX_ENV=test mix local.rebar --force", "MIX_ENV=test mix local.hex --force", "MIX_ENV=test mix deps.get --only=prod"]]})
    assert_received({Bootleg.SSH, :run!, [:conn, ["MIX_ENV=test mix deps.compile", "MIX_ENV=test mix compile"]]})
    assert_received({Bootleg.SSH, :run!, [:conn, "MIX_ENV=test mix release"]})
    assert_received({Bootleg.SSH, :download, [:conn, "_build/test/rel/bootleg/releases/1.0.0/bootleg.tar.gz", ^local_file, []]})
  end
end
