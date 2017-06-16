defmodule Bootleg.Strategies.Deploy.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.Strategies.Deploy.Distillery
  import ExUnit.CaptureIO

  doctest Distillery

  setup do
    use Bootleg.Config

    role :app, "host", user: "user", identity: "identity", workspace: "workspace"

    %{
      project: %Bootleg.Project{
        app_name: "bootleg",
        app_version: "1.0.0"}
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

  test "deploy", %{project: project} do
    capture_io(fn -> assert :ok == Distillery.deploy(project) end)
  end
end
