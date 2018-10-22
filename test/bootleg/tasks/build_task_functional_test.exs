defmodule Bootleg.Tasks.BuildTaskFunctionalTest do
  use Bootleg.DSL
  use Bootleg.FunctionalCase, async: false
  alias Bootleg.Fixtures
  import ExUnit.CaptureIO

  setup %{hosts: [host], role_opts: role_opts} do
    use Bootleg.DSL
    config :app, :build_me
    config :version, "0.1.0"

    workspace = if role_opts[:workspace], do: role_opts[:workspace], else: "workspace"

    role(
      :build,
      host.ip,
      port: host.port,
      user: host.user,
      password: host.password,
      silently_accept_hosts: true,
      workspace: workspace,
      identity: host.private_key_path,
      release_workspace: role_opts[:release_workspace]
    )

    %{
      project_location: Fixtures.inflate_project(),
      docker_image: System.get_env("BOOTLEG_DOCKER_IMAGE")
    }
  end

  test "builds the application", %{project_location: location} do
    use Bootleg.DSL

    File.cd!(location, fn ->
      capture_io(fn ->
        release_name = "#{config(:version)}.tar.gz"
        mix_env = config({:mix_env, "prod"})
        app_name = config(:app)
        app_version = config(:version)
        invoke(:build)

        assert [{:ok, _, 0, _}] =
                 remote(
                   :build,
                   "[ -f _build/#{mix_env}/rel/#{app_name}/releases/#{app_version}/#{app_name}.tar.gz ]"
                 )

        assert true == File.exists?(Path.join([File.cwd!(), "releases", release_name]))
      end)
    end)
  end

  @tag role_opts: %{workspace: "/home/me/workspace_abs"}
  test "builds the application with an absolute workspace path", %{project_location: location} do
    use Bootleg.DSL

    File.cd!(location, fn ->
      capture_io(fn ->
        release_name = "#{config(:version)}.tar.gz"
        mix_env = config({:mix_env, "prod"})
        app_name = config(:app)
        app_version = config(:version)
        invoke(:build)

        assert [{:ok, _, 0, _}] =
                 remote(
                   :build,
                   "[ -f /home/me/workspace_abs/_build/#{mix_env}/rel/#{app_name}/releases/#{
                     app_version
                   }/#{app_name}.tar.gz ]"
                 )

        assert true == File.exists?(Path.join([File.cwd!(), "releases", release_name]))
      end)
    end)
  end

  test "builds the application locally", %{project_location: location} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.DSL

    config :build_type, "local"

    File.cd!(location, fn ->
      capture_io(fn ->
        release_name = "#{config(:version)}.tar.gz"
        assert false == File.exists?("releases/#{release_name}")
        invoke(:build)
        assert true == File.exists?(Path.join([File.cwd!(), "releases", release_name]))
      end)
    end)
  end

  @tag role_opts: %{release_workspace: "/home/me/release_workspace"}
  test "builds the application with a release_workspace path", %{
    hosts: [host],
    project_location: location
  } do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.DSL

    File.cd!(location, fn ->
      capture_io(fn ->
        invoke(:build)
        release_name = "#{config(:version)}.tar.gz"

        assert [{:ok, _, 0, _}] =
                 remote(:build, "[ -f /home/#{host.user}/release_workspace/#{release_name} ]")
      end)
    end)
  end

  test "cleans the workspace before building", %{project_location: location} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.DSL

    File.cd!(location, fn ->
      capture_io(fn ->
        remote(:build, "touch foo.bar")
        remote(:build, "[ -f foo.bar ]")
        invoke(:build)
        assert [{:ok, _, 0, _}] = remote(:build, "[ ! -f foo.bar ]")
      end)
    end)
  end

  test "cleans the customized locations before building", %{project_location: location} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.DSL

    File.cd!(location, fn ->
      capture_io(fn ->
        remote(:build, "touch /tmp/foo.bar")
        remote(:build, "touch foo.car")
        remote(:build, "touch bar.foo")
        remote(:build, "mkdir woo")
        remote(:build, "touch woo/foo")
        remote(:build, "[ -f /tmp/foo.bar ]")
        remote(:build, "[ -f foo.car ]")
        remote(:build, "[ -f bar.foo ]")
        remote(:build, "[ -d woo ]")
        config :clean_locations, ["foo.car", "/tmp/foo.bar", "woo"]
        invoke(:build)
        assert [{:ok, _, 0, _}] = remote(:build, "[ ! -f /foo.bar ]")
        assert [{:ok, _, 0, _}] = remote(:build, "[ ! -f foo.car ]")
        assert [{:ok, _, 0, _}] = remote(:build, "[ -f bar.foo ]")
        assert [{:ok, _, 0, _}] = remote(:build, "[ ! -d woo ]")
      end)
    end)
  end

  @tag timeout: 120_000
  test "the release can be built in docker", %{
    project_location: location,
    docker_image: docker_image_name
  } do
    use Bootleg.DSL
    config(:build_type, :docker)
    config(:docker_build_image, docker_image_name)

    config(
      :docker_build_mount,
      Path.join(File.cwd!(), "test/fixtures/build_me") <> ":/tmp/app/simple"
    )

    config(:ex_path, Path.join(File.cwd!(), "test/fixtures/build_me"))
    config(:release_args, [])

    File.cd!(location, fn ->
      output =
        capture_io(fn ->
          invoke(:build)
        end)

      assert String.match?(output, ~r/Release successfully built!/)
      assert String.match?(output, ~r/Saved: releases\/0.1.0.tar.gz/)
      assert File.exists?("releases/0.1.0.tar.gz")
    end)
  end

  test "docker build is aborted on error", %{docker_image: docker_image_name} do
    use Bootleg.DSL
    config(:build_type, :docker)
    config(:docker_build_image, docker_image_name)

    output =
      capture_io(fn ->
        assert_raise RuntimeError, ~r/Command returned non-zero exit status/, fn ->
          invoke(:build)
        end
      end)

    assert String.match?(output, ~r/Could not find a Mix.Project/)
  end
end
