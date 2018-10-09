defmodule Bootleg.Tasks.ScmTasksFunctionalTest do
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
      project_location: Fixtures.inflate_project()
    }
  end

  test "'git_mode pull' downloads source via git pull" do
    use Bootleg.DSL
    config :git_mode, :pull
    config :repo_url, "/opt/repos/simple.git"

    capture_io(fn ->
      invoke(:remote_scm_update)
      assert [{:ok, _, 0, _}] = remote(:build, "[ -f README.md ]")
      assert [{:ok, [stdout: "Foobar\n"], _, _}] = remote(:build, "cat README.md")
    end)
  end

  test "'git_mode push' uploads source via git push", %{project_location: location} do
    use Bootleg.DSL
    config :git_mode, :push

    File.cd!(location, fn ->
      out =
        capture_io(fn ->
          invoke(:init)
          invoke(:remote_scm_update)
        end)

      assert String.match?(out, ~r/Pushing new commits/)
      assert String.match?(out, ~r/HEAD is now at/)
    end)
  end
end
