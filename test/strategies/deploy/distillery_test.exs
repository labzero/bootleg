defmodule Bootleg.Strategies.Deploy.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.{Strategies.Deploy.Distillery, Fixtures}
  import ExUnit.CaptureIO

  doctest Distillery

  setup do
    use Bootleg.Config

    role :app, "app_host", user: "user", identity: Fixtures.identity_path(), workspace: "workspace"

    %{
      project: %Bootleg.Project{
        app_name: "bootleg",
        app_version: "1.0.0"
      }
    }
  end

  test "init", %{project: project} do
    capture_io(fn ->
      assert %SSHKit.Context{hosts: [%SSHKit.Host{name: "app_host", options: options}], pwd: "workspace", user: nil}
        = Distillery.init(project)
      assert options[:user] == "user"
      assert options[:identity] == Fixtures.identity_path()
    end)
  end

  test "deploy", %{project: project} do
    capture_io(fn -> assert :ok == Distillery.deploy(project) end)
  end
end
