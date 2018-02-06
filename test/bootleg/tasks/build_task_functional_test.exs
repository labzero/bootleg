defmodule Bootleg.Tasks.BuildTaskFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.Fixtures
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
    use Bootleg.Config

    File.cd!(location, fn ->
      capture_io(fn ->
        invoke :build
      end)
    end)
  end

  test "builds the application with an absolute workspace path", %{hosts: [host], project_location: location} do
    use Bootleg.Config

    role :build, host.ip, workspace: "/home/#{host.user}/workspace_abs", port: host.port

    File.cd!(location, fn ->
      capture_io(fn ->
        invoke :build
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
