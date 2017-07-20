defmodule Bootleg.Config do
  @moduledoc """
    Configuration DSL for Bootleg.
  """

  alias Mix.Project
  alias Bootleg.{UI, SSH, Host, Role}

  defmacro __using__(_) do
    quote do
      import Bootleg.Config, only: [role: 2, role: 3, config: 2, config: 0, before_task: 2,
        after_task: 2, invoke: 1, task: 2, remote: 1, remote: 2, load: 1]
    end
  end

  @doc """
  Defines a role.

  Roles are a collection of hosts and their options that are responsible for the same function,
  for example building a release, archiving a release, or executing commands against a running
  application.

  `name` is the name of the role, and is globally unique. Calling `role/3` multiple times with
  the same name will result in the host lists being merged. If the same host shows up mutliple
  times, it will have its `options` merged.

  `hosts` can be a single hostname, or a `List` of hostnames.

  `options` is an optional `Keyword` used to provide configuration details about a specific host
  (or collection of hosts). Certain options are passed to SSH directly (see
  `Bootleg.SSH.supported_options/0`), others are used internally (`user` for example, is used
  by both SSH and Git), and unknown options are simply stored. In the future `remote/1,2` will
  allow for host filtering based on role options. Some Bootleg extensions may also add support
  for additional options.

  ```
  use Bootleg.Config

  role :build, ["build1.example.com", "build2.example.com"], user: "foo", identity: "~/.ssh/id_rsa"
  ```
  """
  defmacro role(name, hosts, options \\ []) do
    # user is in the role options for scm
    user = Keyword.get(options, :user, System.get_env("USER"))
    ssh_options = Enum.filter(options, &Enum.member?(SSH.supported_options, elem(&1, 0)) == true)
    role_options =
      options -- ssh_options
      |> Keyword.put(:user, user)
      # identity needs to be present in both options lists
      |> Keyword.put(:identity, ssh_options[:identity])
      |> Enum.filter(fn {_, v} -> v end)

    quote do
      hosts =
        unquote(hosts)
        |> List.wrap()
        |> Enum.map(&Host.init(&1, unquote(ssh_options), unquote(role_options)))

      new_role = %Role{
        name: unquote(name),
        user: unquote(user),
        hosts: [],
        options: unquote(role_options)
      }
      role =
        :roles
        |> Bootleg.Config.Agent.get()
        |> Keyword.get(unquote(name), new_role)
        |> Role.combine_hosts(hosts)

      Bootleg.Config.Agent.merge(
        :roles,
        unquote(name),
        role
      )
    end
  end

  @doc false
  @spec get_role(atom) :: %Bootleg.Role{} | nil
  def get_role(name) do
    Keyword.get(Bootleg.Config.Agent.get(:roles), name)
  end

  @doc """
  Fetches all key/value pairs currently defined in the Bootleg configuration.
  """
  defmacro config do
    quote do
      Bootleg.Config.Agent.get(:config)
    end
  end

  @doc """
  Sets `key` in the Bootleg configuration to `value`.

  One of the cornerstones of the Bootleg DSL, `config/2` is used to pass configuration options
  to Bootleg. See the documentation for the specific task you are trying to configure for what
  keys it supports.

  ```
  use Bootleg.Config

  config :app, :my_cool_app
  config :version, "1.0.0"
  """
  defmacro config(key, value) do
    quote do
      Bootleg.Config.Agent.merge(
        :config,
        unquote(key),
        unquote(value)
      )
    end
  end

  defp add_callback(task, position, caller, do: block) do
    file = caller.file()
    line = caller.line()
    quote do
      hook_number = Bootleg.Config.Agent.increment(:next_hook_number)
      module_name = String.to_atom("Elixir.Bootleg.Tasks.DynamicCallbacks." <>
        String.capitalize("#{unquote(position)}") <> String.capitalize("#{unquote(task)}") <>
        "#{hook_number}")
      defmodule module_name do
        @file unquote(file)
        def execute, do: unquote(block)
        def location, do: {unquote(file), unquote(line)}
        hook_list_name = :"#{unquote(position)}_hooks"
        hooks = Keyword.get(Bootleg.Config.Agent.get(hook_list_name), unquote(task), [])
        Bootleg.Config.Agent.merge(hook_list_name, unquote(task), hooks ++
          [[module_name, :execute]])
      end
    end
  end

  @doc """
  Defines a before hook for a task.

  A hook is a piece of code that is executed before/after a task has been run. The hook can
  either be a standalone code block, or the name of another task. Hooks are executed in an
  unconditional fashion. Only an uncaught exeception will prevent futher execution. If a task
  name is provided, it will be invoked via `invoke/1`.

  Just like with `invoke/1`, a task does not need to be defined to have a hook registered for
  it, nor does the task need to be defined in order to be triggered via a hook. Tasks may also
  be defined at a later point, provided execution has not begun.

  If multiple hooks are defined for the same task, they are executed in the order they were
  originally defined.

  ```
  use Bootleg.Config

  before_task :build, :checksum_code
  before_task :deploy do
    Notify.team "Here we go!"
  end
  ```

  Relying on the ordering of hook execution is heavily discouraged. It's better to explicitly
  define the order using extra tasks and hooks. For example

  ```
  use Bootleg.Config

  before_task :build, :do_first
  before_task :build, :do_second
  ```

  would be much better written as

  ```
  use Bootleg.Config

  before_task :build, :do_first
  before_task :do_first, :do_second
  ```
  """
  defmacro before_task(task, do: block) when is_atom(task) do
    add_callback(task, :before, __CALLER__, do: block)
  end

  defmacro before_task(task, other_task) when is_atom(task) and is_atom(other_task) do
    quote do: before_task(unquote(task), do: invoke(unquote(other_task)))
  end

  @doc """
  Defines an after hook for a task.

  Behaves exactly like a before hook, but executes after the task has run. See `before_task/2`
  for more details.

  ```
  use Bootleg.Config

  after_task :build, :store_artifact
  after_task :deploy do
    Notify.team "Deployed!"
  end
  ```
  """
  defmacro after_task(task, do: block) when is_atom(task) do
    add_callback(task, :after, __CALLER__, do: block)
  end

  defmacro after_task(task, other_task) when is_atom(task) and is_atom(other_task) do
    quote do: after_task(unquote(task), do: invoke(unquote(other_task)))
  end

  @doc """
  Defines a task idefintied by `task`.

  This is one of the cornerstones of the Bootleg DSL. It takes a task name (`task`) a block of code
  and registers the code to be executed when `task` is invoked. Inside the block, the full Bootleg
  DSL is available.

  A warning will be emitted if a task is redefined.

  ```
  use Bootleg.Config

  task :hello do
    IO.puts "Hello World!"
  end
  ```
  """
  defmacro task(task, do: block) when is_atom(task) do
    file = __CALLER__.file()
    line = __CALLER__.line()
    module_name = module_for_task(task)

    quote do
      if Code.ensure_compiled?(unquote(module_name)) do
        {orig_file, orig_line} = unquote(module_name).location
        UI.warn "warning: task '#{unquote(task)}' is being redefined. " <>
        "The most recent definition will win, but this is probably not what you meant to do. " <>
        "The previous definition was at: #{orig_file}:#{orig_line}"
      end

      original_opts = Code.compiler_options()
      Code.compiler_options(Map.put(original_opts, :ignore_module_conflict, true))

      try do
        defmodule unquote(module_name) do
          @file unquote(file)
          def execute, do: unquote(block)
          def location, do: {unquote(file), unquote(line)}
        end
      after
        Code.compiler_options(original_opts)
      end
      :ok
    end
  end

  @spec invoke_task_callbacks(atom, atom) :: :ok
  defp invoke_task_callbacks(task, agent_key) do
    agent_key
    |> Bootleg.Config.Agent.get()
    |> Keyword.get(task, [])
    |> Enum.each(fn([module, fnref]) -> apply(module, fnref, []) end)
  end

  @spec module_for_task(atom) :: atom
  defp module_for_task(task) do
    :"Elixir.Bootleg.Tasks.DynamicTasks.#{Macro.camelize("#{task}")}"
  end

  @doc """
  Invokes the task identified by `task`.

  This is one of the cornerstones of the Bootleg DSL. Executing a task first calls any registered
  `before_task/2` hooks, then executes the task itself (which was defined via `task/2`), then any
  registered `after_task/2` hooks.

  The execution of the hooks and the task are unconditional. Return values are ignored, though an
  uncuaght exception will stop further execution. The `task` does not need to exist. Any
  hooks for a task with the name of `task` will still be executed, and no error or warning will be
  emitted. This can be used to create events which a developer wants to be able to install hooks
  around without needing to define no-op tasks.

  `invoke/1` executes immediately, so it should always be called from inside a task. If it's placed
  directly inside `config/deploy.exs`, the task will be invoked when the configuration is first
  read. This is probably not what is desired.

  ```
  use Bootleg.Config

  task :hello do
    IO.puts "Hello?"
    invoke :world
  end

  task :world do
    IO.puts "World!"
  end
  ```
  """
  @spec invoke(atom) :: :ok
  def invoke(task) when is_atom(task) do
    invoke_task_callbacks(task, :before_hooks)

    module_name = module_for_task(task)
    if Code.ensure_compiled?(module_name) do
      apply(module_name, :execute, [])
    end

    invoke_task_callbacks(task, :after_hooks)
  end

  @doc """
  Executes commands on all remote hosts.

  This is equivalent to calling `remote/2` with a role of `:all`.
  """
  defmacro remote(do: block) do
    quote do: remote(:all, do: unquote(block))
  end

  defmacro remote(lines) do
    quote do: remote(:all, unquote(lines))
  end

  defmacro remote(role, do: {:__block__, _, lines}) do
    quote do: remote(unquote(role), unquote(lines))
  end

  defmacro remote(role, do: lines) do
    quote do: remote(unquote(role), unquote(lines))
  end

  @doc """
  Executes commands on a remote host.

  This is the workhorse of the DSL. It executes shell commands on all hosts associated with
  the `role`. If any of the shell commands exits with a non-zero status, execution will be stopped
  and an `SSHError` will be raised.

  `lines` can be a `List` of commands to execute, or a code block where each line's return value is
  used as a command. Each command will be simulataneously executed on all hosts in the role. Once
  all hosts have finished executing the command, the next command in the list will be sent.

  `role` can be a single role, a list of roles, or the special role `:all` (all roles). If the same host
  exists in multiple roles, the commands will be run once for each role where the host shows up. In the
  case of multiple roles, each role is processed sequentially.

  Returns the results to the caller, per command and per host. See `Bootleg.SSH.run!` for more details.

  ```
  use Bootleg.Config

  remote :build, ["uname -a", "date"]
  remote :build do
    "ls -la"
    "echo " <> Time.to_string(Time.utc_now) <> " > local_now"
  end

  # will raise an error since `false` exits with a non-zero status
  remote :build, ["false", "touch never_gonna_happen"]

  # runs for hosts found in all roles
  remote do: "hostname"
  remote :all, do: "hostname"

  # runs for hosts found in :build first, then for hosts in :app
  remote [:build, :app], do: "hostname"
  ```
  """
  defmacro remote(role, lines) do
    roles = if role == :all do
      quote do: Keyword.keys(Bootleg.Config.Agent.get(:roles))
    else
      quote do: List.wrap(unquote(role))
    end
    quote do
      Enum.reduce(unquote(roles), [], fn role, outputs ->
        role
        |> SSH.init
        |> SSH.run!(unquote(lines))
        |> SSH.merge_run_results(outputs)
      end)
    end
  end

  @doc """
  Loads a configuration file.

  `file` is the path to the configuration file to be read and loaded. If that file doesn't
  exist `{:error, :enoent}` is returned. If there's an error loading it, a `Code.LoadError`
  exception will be raised.
  """
  @spec load(binary | charlist) :: :ok | {:error, :enoent}
  def load(file) do
    case File.regular?(file) do
      true -> Code.eval_file(file)
              :ok
      false -> {:error, :enoent}
    end
  end

  @doc false
  @spec get_config(atom, any) :: any
  def get_config(key, default \\ nil) do
    Keyword.get(Bootleg.Config.Agent.get(:config), key, default)
  end

  @doc false
  @spec app() :: any
  def app do
    get_config(:app, Project.config[:app])
  end

  @doc false
  @spec version() :: any
  def version do
    get_config(:version, Project.config[:version])
  end
end
