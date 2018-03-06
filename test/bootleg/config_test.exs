defmodule Bootleg.ConfigTest do
  use Bootleg.TestCase, async: false
  alias Bootleg.Config
  alias Config.Agent
  alias Mix.Project
  import ExUnit.CaptureIO
  import Mock

  doctest Bootleg.Config

  defmacro assert_next_received(pattern, failure_message \\ nil) do
    quote do
      failure_message =
        unquote(failure_message) ||
          "The next message does not match #{unquote(Macro.to_string(pattern))}, or the process mailbox is empty."

      receive do
        unquote(pattern) -> true
        _ -> flunk(failure_message)
      after
        0 ->
          flunk(failure_message)
      end
    end
  end

  # credit: https://gist.github.com/henrik/1054546364ac68da4102
  defmacro assert_compile_time_raise(expected_exception, fun) do
    # At compile-time, the fun is in AST form and thus cannot raise.
    # At run-time, we will evaluate this AST, and it may raise.
    fun_quoted_at_runtime = Macro.escape(fun)

    quote do
      assert_raise unquote(expected_exception), fn ->
        Code.eval_quoted(unquote(fun_quoted_at_runtime))
      end
    end
  end

  setup do
    %{
      local_user: System.get_env("USER")
    }
  end

  test "use Bootleg.Config warns about deprecation" do
    assert capture_io(:stderr, fn ->
             use Bootleg.Config
           end) ==
             "\e[33mwarning: \e[0m`use Bootleg.Config` is deprecated; call `use Bootleg.DSL` instead.\n  test/bootleg/config_test.exs:48: Bootleg.ConfigTest.\"test use Bootleg.Config warns about deprecation\"/1\n\n"
  end

  test "get_role/1", %{local_user: local_user} do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.DSL
    role(:build, "build.labzero.com")

    result = Config.get_role(:build)

    assert %Bootleg.Role{
             name: :build,
             hosts: [
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "build.labzero.com", options: []},
                 options: [user: ^local_user]
               }
             ]
           } = result
  end

  test "load/1" do
    Config.load("test/fixtures/deploy.exs")

    roles = Bootleg.Config.Agent.get(:roles)
    config = Bootleg.Config.Agent.get(:config)

    local_user = System.get_env("USER")

    assert %Bootleg.Role{
             hosts: [
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "www1.example.com", options: []},
                 options: [user: ^local_user]
               },
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "www2.example.com", options: []},
                 options: [user: ^local_user]
               },
               %Bootleg.Host{
                 host: %SSHKit.Host{
                   name: "www3.example.com",
                   options: [port: 2222, user: "deploy"]
                 },
                 options: [user: "deploy"]
               }
             ],
             name: :app,
             options: [user: ^local_user],
             user: ^local_user
           } = roles[:app]

    assert %Bootleg.Role{
             hosts: [
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "db.example.com", options: [user: "foo"]},
                 options: [user: "foo", primary: true]
               },
               %Bootleg.Host{
                 host: %SSHKit.Host{name: "db2.example.com", options: [user: "foo"]},
                 options: [user: "foo"]
               }
             ],
             name: :db,
             options: [user: "foo", primary: true],
             user: "foo"
           } = roles[:db]

    assert config[:build_at] == "some path"
    assert config[:replace_me] == "this"
  end

  test "load/1 error" do
    assert {:error, _} = Config.load("invalid_path")
  end

  test "set_key and get_key" do
    assert Config.get_key(:some_key) == nil
    Config.set_key(:some_key, "some value")
    assert Config.get_key(:some_key) == "some value"
  end

  test "get_key with default" do
    assert Config.get_key(:another_key) == nil
    assert Config.get_key(:another_key, :bar) == :bar
  end

  test "app/0" do
    assert Project.config()[:app] == Config.app()
    Config.set_key(:app, "some_app_name")
    assert "some_app_name" == Config.app()
  end

  test "version/0" do
    assert Project.config()[:version] == Config.version()
    Config.set_key(:version, "1.2.3")
    assert "1.2.3" == Config.version()
  end

  test "env/0" do
    assert :production == Config.env()
    Config.set_key(:env, :foo)
    assert :foo == Config.env()
  end

  test "env/1" do
    capture_io(fn ->
      Config.env(:bar)
    end)

    assert :bar == Config.env()
  end

  test_with_mock "env/1 starts the agent", Agent, [:passthrough], [] do
    Config.env(:test)
    assert called(Agent.start_link(:test))
  end
end
