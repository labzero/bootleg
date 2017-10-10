defmodule Bootleg.Config do
  @moduledoc """
    Configuration DSL for Bootleg.
  """

  alias Mix.Project
  alias Bootleg.{UI, SSH, Host, Role}

  defmacro __using__(_) do
    quote do
      import Bootleg.Config, only: [role: 2, role: 3, config: 2, config: 1, config: 0,
        before_task: 2, after_task: 2, invoke: 1, task: 2, remote: 1, remote: 2,
        remote: 3, load: 1, upload: 3]
    end
  end

  @doc """
  Defines a role.

  Roles are a collection of hosts and their options that are responsible for the same function,
  for example building a release, archiving a release, or executing commands against a running
  application.

  `name` is the name of the role, and is globally unique. Calling `role/3` multiple times with
  the same name will result in the host lists being merged. If the same host shows up mutliple
  times, it will have its `options` merged. The name `:all` is reserved and cannot be used here.

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
    if name == :all do
      raise ArgumentError, ":all is reserved by bootleg and refers to all defined roles."
    end
    user = Keyword.get(options, :user, System.get_env("USER"))
    ssh_options = Enum.filter(options, &Enum.member?(SSH.supported_options, elem(&1, 0)) == true)
    role_options =
      options -- ssh_options
      |> Keyword.put(:user, user)
      # identity needs to be present in both options lists
      |> Keyword.put(:identity, ssh_options[:identity])
      |> Keyword.get_and_update(:identity, fn val ->
          if val || Keyword.has_key?(ssh_options, :identity) do
            {val, val || ssh_options[:identity]}
          else
            :pop
          end
        end)
      |> elem(1)

    quote bind_quoted: binding() do
      hosts =
        hosts
        |> List.wrap()
        |> Enum.map(&Host.init(&1, ssh_options, role_options))

      new_role = %Role{
        name: name,
        user: user,
        hosts: [],
        options: role_options
      }
      role =
        :roles
        |> Bootleg.Config.Agent.get()
        |> Keyword.get(name, new_role)
        |> Role.combine_hosts(hosts)

      Bootleg.Config.Agent.merge(
        :roles,
        name,
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
  Fetches the value for the supplied key from the Bootleg configuration. If the provided
  key is a `Tuple`, the first element is considered the key, the second value is considered
  the default value (and returned without altering the config) in case the key has not
  been set. This uses the same semantics as `Keyword.get/3`.

  ```
  use Bootleg.Config
  config :foo, :bar
  
  # local_foo will be :bar
  local_foo = config :foo

  # local_foo will be :bar still, as :foo already has a value
  local_foo = config {:foo, :car}

  # local_hello will be :world, as :hello has not been defined yet
  local_hello = config {:hello, :world}

  config :hello, nil
  # local_hello will be nil, as :hello has a value of nil now
  local_hello = config {:hello, :world}
  ```
  """
  defmacro config({key, default}) do
    quote bind_quoted: binding() do
      Keyword.get(Bootleg.Config.Agent.get(:config), key, default)
    end
  end

  defmacro config(key) do
    quote bind_quoted: binding() do
      Keyword.get(Bootleg.Config.Agent.get(:config), key)
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
  ```
  """
  defmacro config(key, value) do
    quote bind_quoted: binding() do
      Bootleg.Config.Agent.merge(
        :config,
        key,
        value
      )
    end
  end

  defp add_callback(task, position, caller, do: block) do
    file = caller.file()
    line = caller.line()
    quote do
      hook_number = Bootleg.Config.Agent.increment(:next_hook_number)
      module_name = String.to_atom("Elixir.Bootleg.DynamicCallbacks." <>
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
      module_name = unquote(module_name)

      if Code.ensure_compiled?(module_name) do
        {orig_file, orig_line} = module_name.location
        UI.warn "warning: task '#{unquote(task)}' is being redefined. " <>
        "The most recent definition will win, but this is probably not what you meant to do. " <>
        "The previous definition was at: #{orig_file}:#{orig_line}"
      end

      original_opts = Code.compiler_options()
      Code.compiler_options(Map.put(original_opts, :ignore_module_conflict, true))

      try do
        defmodule module_name do
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
    :"Elixir.Bootleg.DynamicTasks.#{Macro.camelize("#{task}")}"
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
    quote do: remote(unquote(role), [], unquote(lines))
  end

  defmacro remote(role, do: lines) do
    quote do: remote(unquote(role), [], unquote(lines))
  end

  @doc """
  Executes commands on all remote hosts within a role.

  This is equivalent to calling `remote/3` with an `options` of `[]`.
  """
  defmacro remote(role, lines) do
    quote do: remote(unquote(role), [], unquote(lines))
  end

  defmacro remote(role, options, do: {:__block__, _, lines}) do
    quote do: remote(unquote(role), unquote(options), unquote(lines))
  end

  defmacro remote(role, options, do: lines) do
    quote do: remote(unquote(role), unquote(options), unquote(lines))
  end

  @doc """
  Executes commands on a remote host.

  This is the workhorse of the DSL. It executes shell commands on all hosts associated with
  the `role`. If any of the shell commands exits with a non-zero status, execution will be stopped
  and an `SSHError` will be raised.

  `lines` can be a `List` of commands to execute, or a code block where each line's return value is
  used as a command. Each command will be simulataneously executed on all hosts in the role. Once
  all hosts have finished executing the command, the next command in the list will be sent.

  `options` is an optional `Keyword` list of options to customize the remote invocation. Currently two
  keys are supported:
  
    * `filter` takes a `Keyword` list of host options to filter with. Any host whose options match
  the filter will be included in the remote execution. A host matches if it has all of the filtering
  options defined and the values match (via `==/2`) the filter.
    * `cd` changes the working directory of the remote shell prior to executing the remote
    commands. The options takes either an absolute or relative path, with relative paths being
    defined relative to the workspace configured for the role, or the default working directory
    of the shell if no workspace is defined.

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

  # only runs on `host1.example.com`
  role :build, "host2.example.com"
  role :build, "host1.example.com", filter: [primary: true, another_attr: :cat]

  remote :build, filter: [primary: true] do
    "hostname"
  end

  # runs on `host1.example.com` inside the `tmp` directory found in the workspace
  remote :build, filter: [primary: true], cd: "tmp/" do
    "hostname"
  end
  ```
  """
  defmacro remote(role, options, lines) do
    roles = unpack_role(role)
    quote bind_quoted: binding() do
      Enum.reduce(roles, [], fn role, outputs ->
        role
        |> SSH.init([cd: options[:cd]], Keyword.get(options, :filter, []))
        |> SSH.run!(lines)
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

  @doc """
  Uploads a local file to remote hosts.

  Uploading works much like `remote/3`, but instead of transferring shell commands over SSH,
  it transfers files via SCP. The remote host does need to support SCP, which should be provided
  by most SSH implementations automatically.

  `role` can either be a single role name, a list of roles, or a list of roles and filter
  attributes. The special `:all` role is also supported. See `remote/3` for details.

  `local_path` can either be a file or directory found on the local machine. If its a directory,
  the entire directory will be recursively copied to the remote hosts. Relative paths are resolved
  relative to the root of the local project.

  `remote_path` is the file or directory where the transfered files should be placed. The semantics
  of how `remote_path` is treated vary depending on what `local_path` refers to. If `local_path` points
  to a file, `remote_path` is treated as a file unless it's `.` or ends in `/`, in which case it's
  treated as a directory and the filename of the local file will be used. If `local_path` is a directory,
  `remote_path` is treated as a directory as well. Relative paths are resolved relative to the projects
  remote `workspace`. Missing directories are not implicilty created.

  The files on the remote server are created using the authenticating user's `uid`/`gid` and `umask`.

  ```
  use Bootleg.Config

  # copies ./my_file to ./new_name on the remote host
  upload :app, "my_file", "new_name"

  # copies ./my_file to ./a_dir/my_file on the remote host. ./a_dir must already exist
  upload :app, "my_file", "a_dir/"

  # recursively copies ./some_dir to ./new_dir on the remote host. ./new_dir will be created if missing
  upload :app, "some_dir", "new_dir"

  # copies ./my_file to /tmp/foo on the remote host
  upload :app, "my_file", "/tmp/foo"
  """
  defmacro upload(role, local_path, remote_path) do
    {roles, filters} = split_roles_and_filters(role)
    roles = unpack_role(roles)
    quote bind_quoted: binding() do
      Enum.each(roles, fn role ->
        role
        |> SSH.init([], filters)
        |> SSH.upload(local_path, remote_path)
      end)
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
    :config
    |> Bootleg.Config.Agent.get()
    |> Keyword.get_lazy(:app, fn -> cache_project_config(:app) end)
  end

  @doc false
  @spec version() :: any
  def version do
    :config
    |> Bootleg.Config.Agent.get()
    |> Keyword.get_lazy(:version, fn -> cache_project_config(:version) end)
  end

  @doc false
  @spec cache_project_config(atom) :: any
  def cache_project_config(prop) do
    unless Project.umbrella? do
      val = Project.config[prop]
      Bootleg.Config.Agent.merge(:config, prop, val)
      val
    else
      nil
    end
  end

  @doc false
  @spec env() :: any
  def env do
    get_config(:env, :production)
  end

  @doc false
  @spec env(any) :: :ok
  def env(env) do
    {:ok, _} = Bootleg.Config.Agent.start_link(env)
    config(:env, env)
  end

  @doc false
  @spec split_roles_and_filters(atom | keyword) :: {[atom], keyword}
  defp split_roles_and_filters(role) do
    role
    |> List.wrap
    |> Enum.split_while(fn term -> !is_tuple(term) end)
  end

  @doc false
  @spec unpack_role(atom | keyword) :: tuple
  defp unpack_role(role) do
    wrapped_role = List.wrap(role)
    if Enum.any?(wrapped_role, fn role -> role == :all end) do
      quote do: Keyword.keys(Bootleg.Config.Agent.get(:roles))
    else
      quote do: unquote(wrapped_role)
    end
  end
end
