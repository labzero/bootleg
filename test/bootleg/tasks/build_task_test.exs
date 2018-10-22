defmodule Bootleg.Tasks.BuildTaskTest do
  use Bootleg.TestCase, async: false
  import ExUnit.CaptureIO
  import Mock
  alias Bootleg.{Config, Git, SSH}

  test "building without specified port" do
    use Bootleg.DSL
    role(:build, "build.example.com", user: "foo", workspace: "bar")

    ssh_host =
      :build
      |> Config.get_role()
      |> Map.get(:hosts)
      |> List.first()
      |> Map.get(:host)

    with_mocks [
      {SSH, [:passthrough],
       [
         init: fn role -> SSH.init(role, []) end,
         init: fn role, _, _ -> SSH.init(role, []) end,
         init: fn _, _ -> %SSHKit.Context{} end,
         run!: fn _, _ -> [{:ok, [stdout: ""], 0, ssh_host}] end,
         ssh_host_options: fn _ -> ssh_host end,
         download: fn _, _, _ -> :ok end
       ]},
      {
        Git,
        [],
        [
          push: fn _, _ -> {"", 0} end,
          push: fn [_, _, host_url, _], _ ->
            case host_url do
              "ssh://foo@build.example.com/~/bar" -> send(self(), :git_push_with_port)
              _ -> :ok
            end

            {"", 0}
          end
        ]
      }
    ] do
      capture_io(fn ->
        invoke(:build)
        assert_received :git_push_with_port
      end)
    end
  end

  test "building in docker without image specified throws an error" do
    use Bootleg.DSL
    config(:build_type, :docker)
    assert_raise RuntimeError, ~r/docker_build_image/, fn -> invoke(:build) end
  end
end
