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
          "mkdir -p releases/1/"
          "sleep 1"
          "mkdir -p releases/2/"
          "ln -s releases/2/ current"
        end
        assert [{:ok, [stdout: "releases/2/"], 0, _}] = remote(:app, "ls -lh current | sed 's/.* //' | tr -d '\n'")
        invoke(:rollback)
        assert [{:ok, [stdout: "releases/1/"], 0, _}] = remote(:app, "ls -lh current | sed 's/.* //' | tr -d '\n'")
      end)
    end)
  end

  test "rollback/1 removes the rolled back release" do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        remote :app do
          "mkdir -p releases/1/"
          "sleep 1"
          "mkdir -p releases/2/"
          "ln -s releases/2/ current"
        end
        invoke(:rollback)
        assert [{:ok, [stdout: "releases/1/"], 0, _}] =
        remote(:app, "ls -1dt releases/*/ | tr -d '\n'")
      end)
    end)
  end
end
