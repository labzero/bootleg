defmodule Bootleg.Config do
  @doc false

  alias Bootleg.{UI, SSH, Host, Role}

  defmacro __using__(_) do
    quote do
      import Bootleg.Config, only: [role: 2, role: 3, config: 2, config: 0, before_task: 2,
        after_task: 2, invoke: 1, task: 2, remote: 1, remote: 2]
      {:ok, agent} = Bootleg.Config.Agent.start_link
      Code.ensure_loaded(Bootleg.Tasks)
      :ok
    end
  end

  defmacro role(name, hosts, options \\ []) do
    # user is in the role options for scm
    user = Keyword.get(options, :user, System.get_env("USER"))
    ssh_options = Enum.filter(options, &Enum.member?(SSH.supported_options, elem(&1, 0)) == true)
    role_options = Keyword.put(options -- ssh_options, :user, user)

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

  def get_role(name) do
    Keyword.get(Bootleg.Config.Agent.get(:roles), name)
  end

  defmacro config do
    quote do
      Bootleg.Config.Agent.get(:config)
    end
  end

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

  defmacro before_task(task, do: block) when is_atom(task) do
    add_callback(task, :before, __CALLER__, do: block)
  end

  defmacro before_task(task, other_task) when is_atom(task) and is_atom(other_task) do
    quote do: before_task(unquote(task), do: invoke(unquote(other_task)))
  end

  defmacro after_task(task, do: block) when is_atom(task) do
    add_callback(task, :after, __CALLER__, do: block)
  end

  defmacro after_task(task, other_task) when is_atom(task) and is_atom(other_task) do
    quote do: after_task(unquote(task), do: invoke(unquote(other_task)))
  end

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

  defp invoke_task_callbacks(task, agent_key) do
    agent_key
    |> Bootleg.Config.Agent.get()
    |> Keyword.get(task, [])
    |> Enum.each(fn([module, fnref]) -> apply(module, fnref, []) end)
  end

  defp module_for_task(task) do
    :"Elixir.Bootleg.Tasks.DynamicTasks.#{Macro.camelize("#{task}")}"
  end

  def invoke(task) when is_atom(task) do
    invoke_task_callbacks(task, :before_hooks)

    module_name = module_for_task(task)
    if Code.ensure_compiled?(module_name) do
      apply(module_name, :execute, [])
    end

    invoke_task_callbacks(task, :after_hooks)
  end

  defmacro remote(do: block) do
    quote do: remote(nil, do: unquote(block))
  end

  defmacro remote(lines) do
    quote do: remote(nil, unquote(lines))
  end

  defmacro remote(role, do: {:__block__, _, lines}) do
    quote do: remote(unquote(role), unquote(lines))
  end

  defmacro remote(role, do: lines) do
    quote do: remote(unquote(role), unquote(lines))
  end

  defmacro remote(role, lines) do
    quote do
      unquote(role)
      |> SSH.init
      |> SSH.run!(unquote(lines))
    end
  end

  @doc """
  Loads a configuration file.

  `file` is the path to the configuration file to be read and loaded. If that file doesn't
  exist or if there's an error loading it, a `Mix.Config.LoadError` exception
  will be raised.

  """
  def load(file) do
    case File.regular?(file) do
      true -> Code.eval_file(file)
      false -> {:error, "File not found"}
    end
  end

  ##################
  ####  LEGACY  ####
  ##################
  @moduledoc """
  Configuration for bootleg in general.

  The configuration is defined as a `Map` in the `Mix.Config` of the target project,
  under the key `:bootleg`. Attributes in the struct have a 1:1 relationship with
  the keys in the `Mix.Config`.

  """

  alias Bootleg.Config.{ManageConfig}
  alias Mix.Project

  @doc false
  @enforce_keys []
  defstruct [:manage]

  @doc """
  Creates a `Bootleg.Config` from the `Application` configuration (under the key `:bootleg`).

  The keys in the map should match the fields in the struct.
  """
  @type strategy :: {:strategy, [...]}
  @spec init([strategy]) :: %Bootleg.Config{}
  def init(options \\ []) do
    %__MODULE__{
      manage: ManageConfig.init(default_option(options, :manage))
    }
  end

  defp default_option(config, key) do
    Keyword.get(config, key, get_config(key))
  end

  def get_config(key, default \\ nil) do
    Keyword.get(Bootleg.Config.Agent.get(:config), key, default)
  end

  def strategy(%Bootleg.Config{} = config, type) do
    get_in(config, [Access.key!(type), Access.key!(:strategy)])
  end

  def app do
    get_config(:app, Project.config[:app])
  end

  def version do
    get_config(:version, Project.config[:version])
  end
end
