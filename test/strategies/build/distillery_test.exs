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
                  identity: "test/fixtures/identity_rsa",
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
    capture_io(fn -> assert %SSHKit.Context{} = Distillery.init(config, project) end)
  end

  test "build", %{config: config, project: project} do
    local_file = "#{File.cwd!}/releases/build.tar.gz"
    capture_io(fn -> assert {:ok, local_file} == Distillery.build(config, project) end)
  end
end
