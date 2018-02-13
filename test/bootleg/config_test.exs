defmodule Bootleg.ConfigTest do
  use Bootleg.TestCase, async: false
  alias Bootleg.{Config, UI, SSH}
  alias Config.Agent
  alias Mix.Project
  import ExUnit.CaptureIO
  import Mock

  doctest Bootleg.Config

  defmacrop roles do
    quote do
      Bootleg.Config.Agent.get(:roles)
    end
  end

  defmacro assert_next_received(pattern, failure_message \\ nil) do
    quote do
      failure_message = unquote(failure_message) ||
        "The next message does not match #{unquote(Macro.to_string(pattern))}, or the process mailbox is empty."
      receive do
        unquote(pattern) -> true
        _ -> flunk(failure_message)
      after 0 ->
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

  test "role/2,3 only unquote the name once" do
    use Bootleg.Config

    role_name = fn ->
      send(self(), :role_name_excuted)
      :foo
    end

    role role_name.(), "foo.example.com"
    send(self(), :next)

    assert_next_received :role_name_excuted
    assert_next_received :next

    role role_name.(), "foo.example.com", an_option: :foo
    send(self(), :next)

    assert_next_received :role_name_excuted
    assert_next_received :next
  end

  test "role/2,3 do not allow a name of :all" do
    assert_compile_time_raise ArgumentError, fn ->
      use Bootleg.Config
      role :all, "build1.example.com"
    end

    assert_compile_time_raise ArgumentError, fn ->
      use Bootleg.Config
      role :all, "build2.example.com", an_option: true
    end
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
    assert config() == [env: :production]

    config :build_at, "some path"
    assert config() == [env: :production, build_at: "some path"]
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

  test "env/0" do
    use Bootleg.Config

    assert :production == Config.env
    config :env, :foo
    assert :foo == Config.env
  end

  test "env/1" do
    capture_io(fn ->
      Config.env(:bar)
    end)
    assert :bar == Config.env
  end

  test_with_mock "env/1 starts the agent", Agent, [:passthrough], [] do
    Config.env(:test)
    assert called Agent.start_link(:test)
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

    Module.create(Bootleg.DynamicTasks.Taskinvoketest, quoted, Macro.Env.location(__ENV__))

    Config.Agent.merge(:before_hooks, :taskinvoketest, [
      [Bootleg.DynamicTasks.Taskinvoketest, :before_hook_1],
      [Bootleg.DynamicTasks.Taskinvoketest, :before_hook_2]
    ])

    Config.Agent.merge(:after_hooks, :taskinvoketest, [
      [Bootleg.DynamicTasks.Taskinvoketest, :after_hook_1],
      [Bootleg.DynamicTasks.Taskinvoketest, :after_hook_2]
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

    module = Bootleg.DynamicTasks.TaskTest
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

  test_with_mock "remote/2", SSH, [:passthrough], [
      init: fn(role, _options, _filter) -> {role} end,
      run!: fn(_, _cmd) -> [:ok] end
    ] do
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

    task :remote_test_all do
      remote :all, do: "echo Hello World All!"
    end

    task :remote_test_all_multi do
      remote :all do
        "echo All Hello"
        "echo All World" <> "!"
      end
    end

    task :remote_test_roles do
      remote [:foo, :bar], do: "echo Hello World Multi!"
    end

    task :remote_test_roles_multi do
      remote [:foo, :bar] do
        "echo Multi Hello"
        "echo Multi World" <> "!"
      end
    end

    role :foo, "never-used-foo.example.com"
    role :bar, "never-used-bar.example.com"

    invoke :remote_test_1

    assert called SSH.init(:test_1, :_, :_)
    assert called SSH.run!({:test_1}, "echo Hello World!")

    invoke :remote_test_2

    assert called SSH.init(:foo, :_, :_)
    assert called SSH.run!({:foo}, "echo Hello World2!")
    assert called SSH.init(:bar, :_, :_)
    assert called SSH.run!({:bar}, "echo Hello World2!")

    invoke :remote_test_3

    assert called SSH.run!({:foo}, ["echo Hello", "echo World!"])
    assert called SSH.run!({:bar}, ["echo Hello", "echo World!"])

    invoke :remote_test_4

    assert called SSH.init(:test_4, :_, :_)
    assert called SSH.run!({:test_4}, ["echo Hello", "echo World"])

    with_mock Time, [], [utc_now: fn -> :now end] do
      task :remote_test_5 do
        remote Time.utc_now
      end

      refute called Time.utc_now

      invoke :remote_test_5

      assert called Time.utc_now
      assert called SSH.run!(:_, :now)
    end

    invoke :remote_test_all

    assert called SSH.init(:foo, :_, :_)
    assert called SSH.run!({:foo}, "echo Hello World All!")
    assert called SSH.init(:bar, :_, :_)
    assert called SSH.run!({:bar}, "echo Hello World All!")

    invoke :remote_test_all_multi

    assert called SSH.run!({:foo}, ["echo All Hello", "echo All World!"])
    assert called SSH.run!({:bar}, ["echo All Hello", "echo All World!"])

    role :car, "never-used-car.example.com"

    invoke :remote_test_roles

    refute called SSH.init(:car, :_, :_)
    assert called SSH.init(:foo, :_, :_)
    assert called SSH.run!({:foo}, "echo Hello World Multi!")
    assert called SSH.init(:bar, :_, :_)
    assert called SSH.run!({:bar}, "echo Hello World Multi!")

    invoke :remote_test_roles_multi

    refute called SSH.init(:car, :_, :_)
    assert called SSH.run!({:foo}, ["echo Multi Hello", "echo Multi World!"])
    assert called SSH.run!({:bar}, ["echo Multi Hello", "echo Multi World!"])
  end

  test_with_mock "remote/3", SSH, [:passthrough], [
      init: fn(role, options, filter) -> {role, options, filter} end,
      run!: fn(_, _cmd) -> [:ok] end
    ] do
    use Bootleg.Config

    task :remote_test_role_one_line_filtered do
      remote :one_line, [filter: [a_filter: true]], "echo Multi Hello"
    end

    task :remote_test_role_inline_filtered do
      remote :inline, [filter: [b_filter: true]], do: "echo Multi Hello"
    end

    task :remote_test_role_filtered do
      remote :car, filter: [passenger: true] do
        "echo Multi Hello"
      end
    end

    task :remote_test_roles_filtered do
      remote [:foo, :bar], filter: [primary: true] do
        "echo Multi Hello"
      end
    end

    task :remote_working_directory_option do
      remote :foo, cd: "/bar" do "echo bar!" end
    end

    task :remote_working_directory_option_nil do
      remote :foo, cd: nil do "echo bar!" end
    end

    task :remote_working_directory_option_none do
      remote :foo do "echo bar!" end
    end

    invoke :remote_test_role_one_line_filtered

    assert called SSH.init(:one_line, :_, a_filter: true)

    invoke :remote_test_role_inline_filtered

    assert called SSH.init(:inline, :_, b_filter: true)

    invoke :remote_test_role_filtered

    assert called SSH.init(:car, :_, passenger: true)

    invoke :remote_test_roles_filtered

    assert called SSH.init(:foo, :_, [primary: true])
    assert called SSH.init(:bar, :_, [primary: true])

    invoke :remote_working_directory_option
    assert called SSH.init(:foo, [cd: "/bar"], [])

    invoke :remote_working_directory_option_nil
    assert called SSH.init(:foo, [cd: nil], [])

    invoke :remote_working_directory_option_none
    assert called SSH.init(:foo, [cd: nil], [])
  end

  test_with_mock "upload/3", SSH, [:passthrough], [
      init: fn(role, options, filter) -> {role, options, filter} end,
      upload: fn(_conn, _local, _remote) -> :ok end,
    ] do
    use Bootleg.Config

    role :foo, "never-used-foo.example.com"
    role :car, "never-used-bar.example.com"

    task :upload_single_role do
      upload :foo, "the/local/path", "some/remote/path"
    end

    task :upload_multi_role do
      upload [:foo, :bar], "the/local/path", "some/remote/path"
    end

    task :upload_all_role do
      upload :all, "the/local/path", "some/remote/path"
    end

    task :upload_single_role_filter do
      upload [:foo, primary: true], "the/local/path", "some/remote/path"
    end

    task :upload_multi_role_filter do
      upload [:foo, :bar, primary: true], "the/local/path", "some/remote/path"
    end

    task :upload_multi_role_complex_filter do
      upload [:foo, :bar, primary: true, db: :mysql], "the/local/path", "some/remote/path"
    end

    task :upload_all_role_filter do
      upload [:all, db: :mysql], "the/local/path", "some/remote/path"
    end

    invoke :upload_single_role

    assert called SSH.init(:foo, [], [])
    assert called SSH.upload({:foo, [], []}, "the/local/path", "some/remote/path")

    invoke :upload_multi_role

    assert called SSH.init(:foo, [], [])
    assert called SSH.init(:bar, [], [])
    assert called SSH.upload({:foo, [], []}, "the/local/path", "some/remote/path")
    assert called SSH.upload({:bar, [], []}, "the/local/path", "some/remote/path")

    invoke :upload_all_role

    assert called SSH.init(:foo, [], [])
    assert called SSH.init(:car, [], [])
    assert called SSH.upload({:foo, [], []}, "the/local/path", "some/remote/path")
    assert called SSH.upload({:car, [], []}, "the/local/path", "some/remote/path")

    invoke :upload_single_role_filter

    assert called SSH.init(:foo, [], [primary: true])
    assert called SSH.upload({:foo, [], [primary: true]}, "the/local/path", "some/remote/path")

    invoke :upload_multi_role_filter

    assert called SSH.init(:foo, [], [primary: true])
    assert called SSH.init(:bar, [], [primary: true])
    assert called SSH.upload({:foo, [], [primary: true]}, "the/local/path", "some/remote/path")
    assert called SSH.upload({:bar, [], [primary: true]}, "the/local/path", "some/remote/path")

    invoke :upload_multi_role_complex_filter

    assert called SSH.init(:foo, [], [primary: true, db: :mysql])
    assert called SSH.init(:bar, [], [primary: true, db: :mysql])
    assert called SSH.upload({:foo, [], [primary: true, db: :mysql]}, "the/local/path", "some/remote/path")
    assert called SSH.upload({:bar, [], [primary: true, db: :mysql]}, "the/local/path", "some/remote/path")

    invoke :upload_all_role_filter

    assert called SSH.init(:foo, [], [db: :mysql])
    assert called SSH.init(:car, [], [db: :mysql])
    assert called SSH.upload({:foo, [], [db: :mysql]}, "the/local/path", "some/remote/path")
    assert called SSH.upload({:car, [], [db: :mysql]}, "the/local/path", "some/remote/path")
  end

  test "config/1" do
    use Bootleg.Config

    refute config(:foo)
    assert config({:foo, :bar}) == :bar
    assert config({:foo, :car}) == :car
    config(:foo, :war)
    assert config(:foo) == :war
    assert config({:foo, :bar}) == :war
    config(:foo, nil)
    assert config({:foo, :bar}) == nil
  end

  test_with_mock "download/3", SSH, [:passthrough], [
      init: fn(role, options, filter) -> {role, options, filter} end,
      download: fn(_conn, _remote, _local) -> :ok end,
    ] do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config

    role :foo, "never-used-foo.example.com"
    role :car, "never-used-bar.example.com"

    download :foo, "some/remote/path", "the/local/path"

    assert called SSH.init(:foo, [], [])
    assert called SSH.download({:foo, [], []}, "some/remote/path", "the/local/path")

    download [:foo, :bar], "some/remote/path", "the/local/path"

    assert called SSH.init(:foo, [], [])
    assert called SSH.init(:bar, [], [])
    assert called SSH.download({:foo, [], []}, "some/remote/path", "the/local/path")
    assert called SSH.download({:bar, [], []}, "some/remote/path", "the/local/path")

    download :all, "some/remote/path", "the/local/path"

    assert called SSH.init(:foo, [], [])
    assert called SSH.init(:car, [], [])
    assert called SSH.download({:foo, [], []}, "some/remote/path", "the/local/path")
    assert called SSH.download({:car, [], []}, "some/remote/path", "the/local/path")

    download [:foo, primary: true], "some/remote/path", "the/local/path"

    assert called SSH.init(:foo, [], [primary: true])
    assert called SSH.download({:foo, [], [primary: true]}, "some/remote/path", "the/local/path")

    download [:foo, :bar, primary: true], "some/remote/path", "the/local/path"

    assert called SSH.init(:foo, [], [primary: true])
    assert called SSH.init(:bar, [], [primary: true])
    assert called SSH.download({:foo, [], [primary: true]}, "some/remote/path", "the/local/path")
    assert called SSH.download({:bar, [], [primary: true]}, "some/remote/path", "the/local/path")

    download [:foo, :bar, primary: true, db: :mysql], "some/remote/path", "the/local/path"

    assert called SSH.init(:foo, [], [primary: true, db: :mysql])
    assert called SSH.init(:bar, [], [primary: true, db: :mysql])
    assert called SSH.download({:foo, [], [primary: true, db: :mysql]}, "some/remote/path", "the/local/path")
    assert called SSH.download({:bar, [], [primary: true, db: :mysql]}, "some/remote/path", "the/local/path")

    download [:all, db: :mysql], "some/remote/path", "the/local/path"

    assert called SSH.init(:foo, [], [db: :mysql])
    assert called SSH.init(:car, [], [db: :mysql])
    assert called SSH.download({:foo, [], [db: :mysql]}, "some/remote/path", "the/local/path")
    assert called SSH.download({:car, [], [db: :mysql]}, "some/remote/path", "the/local/path")
  end
end
