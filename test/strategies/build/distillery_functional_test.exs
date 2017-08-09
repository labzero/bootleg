defmodule Bootleg.Strategies.Build.DistilleryFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.{Strategies.Build.Distillery, Fixtures}
  import ExUnit.CaptureIO

  setup %{hosts: [host]} do
    use Bootleg.Config
    config :app, :build_me
    config :version, "0.1.0"

    role :build, host.ip, port: host.port, user: host.user, password: host.password,
      silently_accept_hosts: true, workspace: "workspace", identity: host.private_key_path

    %{
      project_location: Fixtures.inflate_project
    }
  end

  test "builds the application", %{project_location: location} do
    File.cd!(location, fn ->
      capture_io(fn ->
        assert {:ok, filename} = Distillery.build()
        assert File.regular?(filename)
        assert "#{File.cwd!}/releases/0.1.0.tar.gz" == filename
      end)
    end)
  end

  test "builds the application with an absolute workspace path", %{hosts: [host], project_location: location} do
    use Bootleg.Config

    role :build, host.ip, workspace: "/home/#{host.user}/workspace_abs", port: host.port

    File.cd!(location, fn ->
      capture_io(fn ->
        assert {:ok, filename} = Distillery.build()
        assert File.regular?(filename)
        assert "#{File.cwd!}/releases/0.1.0.tar.gz" == filename
      end)
    end)
  end

  test "cleans the workspace before building", %{project_location: location} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config

    File.cd!(location, fn ->
      capture_io(fn ->
        remote :build, "touch foo.bar"
        remote :build, "[ -f foo.bar ]"
        assert {:ok, _} = Distillery.build()
        assert [{:ok, _, 0, _}] = remote :build, "[ ! -f foo.bar ]"
      end)
    end)
  end
end
