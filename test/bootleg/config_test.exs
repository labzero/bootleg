defmodule Bootleg.ConfigTest do
  use ExUnit.Case, async: true
  alias Bootleg.Config

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

  test "role/2" do
    use Bootleg.Config
    assert roles() == []

    role :build, "build.labzero.com"
    result = roles()
    assert [build: %Bootleg.Role{hosts: ["build.labzero.com"], name: :build, options: [], user: user}] = result
    assert user == System.get_env("USER")
  end

  test "role/3" do
    use Bootleg.Config
    assert roles() == []

    role :build, "build.labzero.com", user: "brien"
    assert roles() ==
      [build: %Bootleg.Role{hosts: ["build.labzero.com"], name: :build, options: [], user: "brien"}]
  end

  test "get_role/1" do
    use Bootleg.Config
    role :build, "build.labzero.com"

    result = Config.get_role(:build)
    assert %Bootleg.Role{name: :build, hosts: ["build.labzero.com"]} = result
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

  test "config file" do
    Code.eval_file(Path.relative_to_cwd("test/fixtures/deploy.exs"))

    roles = Bootleg.Config.Agent.get(:roles)
    config = Bootleg.Config.Agent.get(:config)

    assert %Bootleg.Role{hosts: ["www1.example.com", "www2.example.com"], name: :app, options: [], user: user}
      = roles[:app]
    assert user == System.get_env("USER")
    assert %Bootleg.Role{hosts: ["db.example.com"], name: :db, options: [primary: true], user: "foo"}
      = roles[:db]
    assert %Bootleg.Role{hosts: ["replacement.example.com"], name: :replace, options: [bar: :car], user: user}
      = roles[:replace]
    assert user == System.get_env("USER")

    assert config[:build_at] == "some path"
    assert config[:replace_me] == "this"
  end

  test "get_config" do
    use Bootleg.Config

    config :some_key, "some value"

    assert Config.get_config(:some_key) == "some value"
    assert Config.get_config(:another_key) == nil
    assert Config.get_config(:another_key, :bar) == :bar
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
    assert [[_, :execute]] = hooks[:before_task_test]
  end
  test "after_task/2" do
    use Bootleg.Config

    after_task :after_task_test, :some_other_task
    hooks = Config.Agent.get(:after_hooks)
    assert [[_, :execute]] = hooks[:after_task_test]
  end
  test "task/2" do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config

    task :task_test, do: true

    assert apply(Bootleg.Tasks.DynamicTasks.Task_test, :execute, [])
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
end
