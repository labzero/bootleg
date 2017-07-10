defmodule Bootleg.Strategies.Deploy.DistilleryFunctionalTest do
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.Strategies.Deploy.Distillery
  import ExUnit.CaptureIO

  setup %{hosts: [host]} do
    use Bootleg.Config
    role :app, [host.ip], port: host.port, user: host.user, password: host.password,
      silently_accept_hosts: true, workspace: "workspace"

    config :app, "my_app"
    config :version, "valid_archive"
  end

  @tag boot: 1
  test "deploy/1 returns an error if there is no file to upload" do
    use Bootleg.Config

    config :app, "my_missing_app"
    config :version, "missing"

    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert_raise File.Error, fn -> Distillery.deploy() end
      end)
    end)
  end

  @tag boot: 1
  test "deploy/1 returns an error if the unpack fails" do
    use Bootleg.Config

    config :app, "my_bad_archive_app"
    config :version, "bad_archive"

    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert_raise SSHError, fn -> Distillery.deploy() end
      end)
    end)
  end

  @tag boot: 1
  test "deploy/1 deploys the release to the target hosts" do
    File.cd!("test/fixtures", fn ->
      capture_io(fn ->
        assert :ok = Distillery.deploy()
      end)
    end)
  end

  @tag boot: 1
  test "init/1 initializes the SSH context", %{hosts: [host]} do
    capture_io(fn ->
      assert %SSHKit.Context{
        hosts: [%SSHKit.Host{name: hostname, options: options}], path: "workspace", user: nil
      } = Distillery.init()
      assert hostname == host.ip
      assert options[:user] == host.user
      assert options[:silently_accept_hosts] == true
      assert options[:port] == host.port
    end)
  end

  test "init/1 raises an error if the host is not found" do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config
    role :app, "bad-host-name.local"
    capture_io(fn ->
      assert_raise SSHError, fn -> Distillery.init() end
    end)
  end
end
