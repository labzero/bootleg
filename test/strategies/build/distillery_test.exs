defmodule Bootleg.Strategies.Build.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.Strategies.Build.Distillery
  import ExUnit.CaptureIO

  doctest Distillery

  setup do
    use Bootleg.Config

    role :build, "host", user: "user", identity: "identity", workspace: "workspace"

    %{
      project: %Bootleg.Project{
        app_name: "bootleg",
        app_version: "1.0.0"
      }
    }
  end

  test "init", %{project: project} do
    capture_io(fn ->
      assert %SSHKit.Context{hosts: [%SSHKit.Host{name: "host", options: options}], pwd: "workspace", user: nil}
        = Distillery.init(project)
      assert options[:user] == "user"
      assert options[:identity] == "identity"
    end)
  end

  test "build", %{project: project} do
    local_file = "#{File.cwd!}/releases/build.tar.gz"
    capture_io(fn -> assert {:ok, local_file} == Distillery.build(project) end)
  end
end
