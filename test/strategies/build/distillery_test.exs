defmodule Bootleg.Strategies.Build.DistilleryTest do
  use ExUnit.Case, async: false
  alias Bootleg.{Strategies.Build.Distillery, Fixtures}
  import ExUnit.CaptureIO

  doctest Distillery

  setup do
    use Bootleg.Config

    role :build, "build_host", user: "user", identity: Fixtures.identity_path(), workspace: "workspace"
  end

  @tag skip: "Migrate to functional test"
  test "init" do
    capture_io(fn ->
      assert %SSHKit.Context{hosts: [%SSHKit.Host{name: "build_host", options: options}], path: "workspace", user: nil}
        = Distillery.init()
      assert options[:user] == "user"
      assert options[:identity] == Fixtures.identity_path()
    end)
  end

  @tag skip: "Migrate to functional test"
  test "build" do
    local_file = "#{File.cwd!}/releases/build.tar.gz"
    capture_io(fn -> assert {:ok, local_file} == Distillery.build() end)
  end
end
