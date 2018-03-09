defmodule Bootleg.Tasks.DeployTaskFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  use Bootleg.DSL
  import ExUnit.CaptureIO

  setup %{hosts: [host], role_opts: role_opts} do
    role(
      :app,
      [host.ip],
      port: host.port,
      user: host.user,
      password: host.password,
      silently_accept_hosts: true,
      workspace: "workspace",
      release_workspace: role_opts[:release_workspace]
    )

    config :app, "my_app"
    config :version, "valid_archive"
  end

  test "deploy/1 returns an error if there is no file to upload" do
    config :app, "my_missing_app"
    config :version, "missing"

    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert_raise File.Error, fn -> invoke(:deploy) end
      end)
    end)
  end

  test "deploy/1 returns an error if the unpack fails" do
    config :app, "my_bad_archive_app"
    config :version, "bad_archive"

    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert_raise SSHError, fn -> invoke(:deploy) end
      end)
    end)
  end

  test "deploy/1 deploys the release to the target hosts" do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        invoke(:deploy)
      end)
    end)
  end

  @tag role_opts: %{release_workspace: "/fixtures"}
  test "deploy/1 deploys the release to the target hosts from a remote release_workspace path" do
    alias Bootleg.Config

    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        release_name = "#{Config.version()}.tar.gz"
        app_name = "#{Config.app()}.tar.gz"
        assert [{:ok, _, 0, _}] = remote(:app, "[ -f /fixtures/#{release_name} ]")
        invoke(:deploy)
        assert [{:ok, _, 0, _}] = remote(:app, "[ -f #{app_name} ]")
        assert [{:ok, _, 0, _}] = remote(:app, "[ -f release.txt ]")
      end)
    end)
  end
end
