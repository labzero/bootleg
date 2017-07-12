defmodule Bootleg.FunctionalTest do
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.Fixtures
  import ExUnit.CaptureIO

  setup %{hosts: hosts} do
    build_host = List.first(hosts)
    app_hosts = hosts -- [build_host]

    use Bootleg.Config
    role :build, build_host.ip, port: build_host.port, user: build_host.user,
      silently_accept_hosts: true, workspace: "workspace", identity: build_host.private_key_path

    Enum.each(app_hosts, fn host ->
      role :app, host.ip, port: host.port, user: host.user,
        silently_accept_hosts: true, workspace: "workspace", identity: host.private_key_path
    end)

    config :app, :build_me
    config :version, "0.1.0"

    %{
      project_location: Fixtures.inflate_project
    }
  end

  @tag boot: 3
  test "build, deploy, and manage", %{project_location: location} do
    File.cd!(location, fn ->
      capture_io(fn ->
        # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
        use Bootleg.Config

        invoke :build
        invoke :deploy
        invoke :start
      end)
    end)
  end

end
