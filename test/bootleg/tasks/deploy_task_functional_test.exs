defmodule Bootleg.Tasks.DeployTaskFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  use Bootleg.Config
  import ExUnit.CaptureIO

  setup %{hosts: [host]} do
    role :app, [host.ip], port: host.port, user: host.user, password: host.password,
      silently_accept_hosts: true, workspace: "workspace"

    config :app, "my_app"
    config :version, "valid_archive"
  end

  test "deploy/1 returns an error if there is no file to upload" do
    config :app, "my_missing_app"
    config :version, "missing"

    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert_raise File.Error, fn -> invoke :deploy end
      end)
    end)
  end

  test "deploy/1 returns an error if the unpack fails" do
    config :app, "my_bad_archive_app"
    config :version, "bad_archive"

    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert_raise SSHError, fn -> invoke :deploy end
      end)
    end)
  end

  test "deploy/1 deploys the release to the target hosts" do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        invoke :deploy
      end)
    end)
  end
end
