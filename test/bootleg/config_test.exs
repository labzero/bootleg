defmodule Bootleg.ConfigTest do
  use ExUnit.Case, async: false
  alias Bootleg.{Config, UI, SSH}
  alias Mix.Project
  import Mock

  doctest Bootleg.Config

  defmacrop roles do
    quote do
      Bootleg.Config.Agent.get(:roles)
    end
  end

  defmacro assert_next_received(pattern, failure_message \\ nil) do
    quote do
      receive do
        unquote(pattern) -> true
      after 0 ->
        flunk(unquote(failure_message) ||
          "The next message does not match #{unquote(Macro.to_string(pattern))}, or the process mailbox is empty."
        )
      end
    end
  end

  setup do
    %{
      local_user: System.get_env("USER")
    }
  end

  test "role/2", %{local_user: local_user} do
    use Bootleg.Config
    assert roles() == []

    role :build, "build.labzero.com"
    result = roles()
    assert [
      build: %Bootleg.Role{
        hosts: [
          %Bootleg.Host{
            host: %SSHKit.Host{name: "build.labzero.com", options: []},
            options: [user: ^local_user]
          }
        ],
        name: :build,
        options: [user: ^local_user],
        user: ^local_user}
    ] = result
  end

  test "role/3" do
    use Bootleg.Config
    assert roles() == []

    role :build, "build.labzero.com", user: "brien"
    assert roles() == [
      build: %Bootleg.Role{
        hosts: [
          %Bootleg.Host{
            host: %SSHKit.Host{name: "build.labzero.com", options: [user: "brien"]},
            options: [user: "brien"]
          }
        ],
        name: :build,
        options: [user: "brien"],
        user: "brien"
      }
    ]

    role :build, "build.labzero.com", port: 123
    role :build, "build.labzero.com", port: 123, user: "foo"
    assert [build: %Bootleg.Role{hosts: hosts}] = roles()
    assert Enum.count(hosts) == 2
  end

  test "get_role/1", %{local_user: local_user} do
    use Bootleg.Config
    role :build, "build.labzero.com"

    result = Config.get_role(:build)
    assert %Bootleg.Role{name: :build, hosts: [%Bootleg.Host{host: %SSHKit.Host{name: "build.labzero.com",
      options: []}, options: [user: ^local_user]}]} = result
  end

  test "config/0" do
    use Bootleg.Config
    Bootleg.Config.Agent.put(:config, [foo: :bar])
    assert config() == [foo: :bar]
  end

  test "config/2" do
    use Bootleg.Config
    assert config() == []

    config :build_at, "some path"
    assert config() == [build_at: "some path"]
  end

  test "load/1" do
    Config.load("test/fixtures/deploy.exs")

    roles = Bootleg.Config.Agent.get(:roles)
    config = Bootleg.Config.Agent.get(:config)

    local_user = System.get_env("USER")

    assert %Bootleg.Role{hosts: [
      %Bootleg.Host{host: %SSHKit.Host{name: "www1.example.com",
        options: []}, options: [user: ^local_user]},
      %Bootleg.Host{host: %SSHKit.Host{name: "www2.example.com",
        options: []}, options: [user: ^local_user]},
      %Bootleg.Host{host: %SSHKit.Host{name: "www3.example.com",
        options: [port: 2222, user: "deploy"]},
        options: [user: "deploy"]},
    ], name: :app, options: [user: ^local_user], user: ^local_user}
      = roles[:app]
    assert %Bootleg.Role{hosts: [
      %Bootleg.Host{
        host: %SSHKit.Host{name: "db.example.com", options: [user: "foo"]},
        options: [user: "foo", primary: true]},
      %Bootleg.Host{
        host: %SSHKit.Host{name: "db2.example.com", options: [user: "foo"]},
        options: [user: "foo"]},
      ], name: :db, options: [user: "foo", primary: true], user: "foo"} = roles[:db]

    assert config[:build_at] == "some path"
    assert config[:replace_me] == "this"
  end

  test "load/1 error" do
    assert {:error, _} = Config.load("invalid_path")
  end

  test "get_config" do
    use Bootleg.Config

    config :some_key, "some value"

    assert Config.get_config(:some_key) == "some value"
    assert Config.get_config(:another_key) == nil
    assert Config.get_config(:another_key, :bar) == :bar
  end

  test "app/0" do
    use Bootleg.Config

    assert Project.config[:app] == Config.app
    config :app, "some_app_name"
    assert "some_app_name" == Config.app
  end

  test "version/0" do
    use Bootleg.Config

    assert Project.config[:version] == Config.version
    config :version, "1.2.3"
    assert "1.2.3" == Config.version
  end

  test "invoke/1" do
    use Bootleg.Config

    quoted = quote do
      def execute do
        send self(), {:invoke, :invoke_test}
      end
      def before_hook_1 do
        send self(), {:before, :invoke_test, 1}
      end
      def before_hook_2 do
        send self(), {:before, :invoke_test, 2}
      end
      def after_hook_1 do
        send self(), {:after, :invoke_test, 1}
      end
      def after_hook_2 do
        send self(), {:after, :invoke_test, 2}
      end
    end

    Module.create(Bootleg.Tasks.DynamicTasks.Taskinvoketest, quoted, Macro.Env.location(__ENV__))

    Config.Agent.merge(:before_hooks, :taskinvoketest, [
      [Bootleg.Tasks.DynamicTasks.Taskinvoketest, :before_hook_1],
      [Bootleg.Tasks.DynamicTasks.Taskinvoketest, :before_hook_2]
    ])

    Config.Agent.merge(:after_hooks, :taskinvoketest, [
      [Bootleg.Tasks.DynamicTasks.Taskinvoketest, :after_hook_1],
      [Bootleg.Tasks.DynamicTasks.Taskinvoketest, :after_hook_2]
    ])

    invoke :taskinvoketest

    assert_next_received {:before, :invoke_test, 1}
    assert_next_received {:before, :invoke_test, 2}
    assert_next_received {:invoke, :invoke_test}
    assert_next_received {:after, :invoke_test, 1}
    assert_next_received {:after, :invoke_test, 2}
  end

  test "before_task/2" do
    use Bootleg.Config

    before_task :before_task_test, :some_other_task
    hooks = Config.Agent.get(:before_hooks)
    assert [[module, :execute]] = hooks[:before_task_test]
    assert {file, line} = module.location
    assert file == __ENV__.file
    assert line
  end

  test "after_task/2" do
    use Bootleg.Config

    after_task :after_task_test, :some_other_task
    hooks = Config.Agent.get(:after_hooks)
    assert [[module, :execute]] = hooks[:after_task_test]
    assert {file, line} = module.location
    assert file == __ENV__.file
    assert line
  end

  test_with_mock "task/2", UI, [], [warn: fn(_string) -> :ok end] do
    use Bootleg.Config

    task :task_test, do: true

    module = Bootleg.Tasks.DynamicTasks.TaskTest
    assert apply(module, :execute, [])
    assert {file, line} = module.location
    assert file == __ENV__.file
    assert line
    refute called UI.warn(:_)
  end

  test_with_mock "task/2 redefine task warning", UI, [], [warn: fn(_string) -> :ok end] do
    use Bootleg.Config

    task :task_redefine_test, do: true
    task :task_redefine_test, do: false
    assert called UI.warn(:_)
  end

  test "hooks" do
    Code.eval_file(Path.relative_to_cwd("test/fixtures/deploy_with_hooks.exs"))

    Config.invoke :foo

    assert_next_received {:task, :bar}
    assert_next_received {:before, :hello}
    assert_next_received {:after, :hello}
    assert_next_received {:before, :foo}
    assert_next_received {:task, :foo}
    assert_next_received {:task, :another_task}
    assert_next_received {:after, :another_task}
    refute_received {:task, :hello}

    Config.invoke :bar

    assert_next_received {:task, :bar}
    assert_next_received {:before, :hello}
    assert_next_received {:after, :hello}
    refute_received {:task, :hello}
    refute_received {:before, :foo}
  end

  test_with_mock "remote/2", SSH, [], [init: fn(role) -> {role} end, run!: fn(_, _cmd) -> :ok end] do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config

    task :remote_test_1 do
      remote :test_1, do: "echo Hello World!"
    end

    task :remote_test_2 do
      remote do: "echo Hello World2!"
    end

    task :remote_test_3 do
      remote do
        "echo Hello"
        "echo World" <> "!"
      end
    end

    task :remote_test_4 do
      remote :test_4, ["echo Hello", "echo World"]
    end

    invoke :remote_test_1

    assert called SSH.init(:test_1)
    assert called SSH.run!({:test_1}, "echo Hello World!")

    invoke :remote_test_2

    assert called SSH.init(nil)
    assert called SSH.run!({nil}, "echo Hello World2!")

    invoke :remote_test_3

    assert called SSH.run!({nil}, ["echo Hello", "echo World!"])

    invoke :remote_test_4

    assert called SSH.init(:test_4)
    assert called SSH.run!({:test_4}, ["echo Hello", "echo World"])

    with_mock Time, [], [utc_now: fn -> :now end] do
      task :remote_test_5 do
        remote Time.utc_now
      end

      refute called Time.utc_now

      invoke :remote_test_5

      assert called Time.utc_now
      assert called SSH.run!({nil}, :now)
    end
  end
end
