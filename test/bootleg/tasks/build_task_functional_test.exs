defmodule Bootleg.Tasks.BuildTaskFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.Fixtures
  import ExUnit.CaptureIO

  setup %{hosts: [host], role_opts: role_opts} do
    use Bootleg.Config
    config :app, :build_me
    config :version, "0.1.0"
    workspace = if role_opts[:workspace], do: role_opts[:workspace], else: "workspace"

    role :build, host.ip, port: host.port, user: host.user, password: host.password,
      silently_accept_hosts: true, workspace: workspace, identity: host.private_key_path,
      release_workspace: role_opts[:release_workspace]

    %{
      project_location: Fixtures.inflate_project
    }
  end

  test "builds the application", %{project_location: location} do
    use Bootleg.Config

    File.cd!(location, fn ->
      capture_io(fn ->
        invoke :build
      end)
    end)
  end

  @tag role_opts: %{workspace: "/home/me/workspace_abs"}
  test "builds the application with an absolute workspace path", %{project_location: location} do
    use Bootleg.Config

    File.cd!(location, fn ->
      capture_io(fn ->
        invoke :build
      end)
    end)
  end

  @tag role_opts: %{release_workspace: "/home/me/release_workspace"}
  test "builds the application with a release_workspace path", %{hosts: [host], project_location: location} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    alias Bootleg.Config

    File.cd!(location, fn ->
      capture_io(fn ->
        invoke :build
        release_name = "#{Config.version()}.tar.gz"
        assert [{:ok, _, 0, _}] = remote :build, "[ -f /home/#{host.user}/release_workspace/#{release_name} ]"
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
        invoke :build
        assert [{:ok, _, 0, _}] = remote :build, "[ ! -f foo.bar ]"
      end)
    end)
  end

  test "cleans the customized locations before building", %{project_location: location} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config

    File.cd!(location, fn ->
      capture_io(fn ->
        remote :build, "touch /tmp/foo.bar"
        remote :build, "touch foo.car"
        remote :build, "touch bar.foo"
        remote :build, "mkdir woo"
        remote :build, "touch woo/foo"
        remote :build, "[ -f /tmp/foo.bar ]"
        remote :build, "[ -f foo.car ]"
        remote :build, "[ -f bar.foo ]"
        remote :build, "[ -d woo ]"
        config :clean_locations, ["foo.car", "/tmp/foo.bar", "woo"]
        invoke :build
        assert [{:ok, _, 0, _}] = remote :build, "[ ! -f /foo.bar ]"
        assert [{:ok, _, 0, _}] = remote :build, "[ ! -f foo.car ]"
        assert [{:ok, _, 0, _}] = remote :build, "[ -f bar.foo ]"
        assert [{:ok, _, 0, _}] = remote :build, "[ ! -d woo ]"
      end)
    end)
  end
end
