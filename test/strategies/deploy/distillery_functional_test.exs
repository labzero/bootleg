defmodule Bootleg.Strategies.Deploy.DistilleryFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.Strategies.Deploy.Distillery
  import ExUnit.CaptureIO

  setup %{hosts: [host]} do
    use Bootleg.Config
    role :app, host.ip, port: host.port, user: host.user, password: host.password,
      silently_accept_hosts: true, workspace: "workspace"

    %{
      project: %Bootleg.Project{
        app_name: "my_app",
        app_version: "valid_archive"
      },
      missing_project: %Bootleg.Project{
        app_name: "my_missing_app",
        app_version: "missing"
      },
      bad_archive_project: %Bootleg.Project{
        app_name: "my_bad_archive_app",
        app_version: "bad_archive"
      }
    }
  end

  @tag boot: 1
  test "deploy/1 returns an error if there is no file to upload", %{missing_project: project} do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert_raise File.Error, fn -> Distillery.deploy(project) end
      end)
    end)
  end

  @tag boot: 1
  test "deploy/1 returns an error if the unpack fails", %{bad_archive_project: project} do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert_raise SSHError, fn -> Distillery.deploy(project) end
      end)
    end)
  end

  @tag boot: 1
  test "deploy/1 deploys the release to the target hosts", %{project: project} do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert :ok = Distillery.deploy(project)
      end)
    end)
  end

  @tag boot: 1
  test "init/1 initializes the SSH context", %{hosts: [host], project: project} do
    capture_io(fn ->
      assert %SSHKit.Context{
        hosts: [%SSHKit.Host{name: hostname, options: options}], path: "workspace", user: nil
      } = Distillery.init(project)
      assert hostname == host.ip
      assert options[:user] == host.user
      assert options[:silently_accept_hosts] == true
      assert options[:port] == host.port
    end)
  end

  test "init/1 raises an error if the host is not found", %{project: project} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config
    role :app, "bad-host-name.local"
    capture_io(fn ->
      assert_raise SSHError, fn -> Distillery.init(project) end
    end)
  end
end
