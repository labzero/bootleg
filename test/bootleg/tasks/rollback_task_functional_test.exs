defmodule Bootleg.Tasks.RollbackTaskFunctionalTest do
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

  test "rollback/1 returns an error if there is no release to rollback to" do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        remote :app do
          "mkdir -p releases/2/"
          "ln -s releases/2/ current"
        end

        assert_raise SSHError, fn -> invoke(:rollback) end
      end)
    end)
  end

  test "rollback/1 rollsback the release" do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        remote :app do
          "mkdir -p releases/1/bin/"
          "touch releases/1/bin/my_app"
          "sleep 1"
          "mkdir -p releases/2/bin"
          "touch releases/2/bin/my_app"
          "ln -s releases/2/ current"
        end
        current_release = "ls -lh current | sed 's/.* //' | tr -d '\n'"
        assert [{:ok, [stdout: "releases/2/"], 0, _}] = remote(:app, current_release)

        invoke(:rollback)

        assert [{:ok, [stdout: "releases/1/"], 0, _}] = remote(:app, current_release)
      end)
    end)
  end

  test "rollback/1 removes the rolled back release" do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        remote :app do
          "mkdir -p releases/1/bin/"
          "touch releases/1/bin/my_app"
          "sleep 1"
          "mkdir -p releases/2/bin/"
          "touch releases/2/bin/my_app"
          "ln -s releases/2/ current"
        end

        invoke(:rollback)

        list_releases = "ls -1dt releases/*/ | tr -d '\n'"
        assert [{:ok, [stdout: "releases/1/"], 0, _}] = remote(:app, list_releases)
      end)
    end)
  end
end
