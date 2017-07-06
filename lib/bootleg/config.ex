defmodule Bootleg.Config do
  @doc false

  alias Bootleg.UI

  defmacro __using__(_) do
    quote do
      import Bootleg.Config, only: [role: 2, role: 3, config: 2, config: 0, before_task: 2,
        after_task: 2, invoke: 1, task: 2]
      {:ok, agent} = Bootleg.Config.Agent.start_link
      Code.ensure_loaded(Bootleg.Tasks)
      :ok
    end
  end

  defmacro role(name, hosts, options \\ []) do
    host_list = List.wrap(hosts)
    user = Keyword.get(options, :user, System.get_env("USER"))
    options = Keyword.delete(options, :user)
    quote do
      Bootleg.Config.Agent.merge(
        :roles,
        unquote(name),
        %Bootleg.Role{
          name: unquote(name), hosts: unquote(host_list), user: unquote(user),
          options: unquote(options)
        }
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
    :"Elixir.Bootleg.Tasks.DynamicTasks.#{String.capitalize("#{task}")}"
  end

  def invoke(task) when is_atom(task) do
    invoke_task_callbacks(task, :before_hooks)

    module_name = module_for_task(task)
    if Code.ensure_compiled?(module_name) do
      apply(module_name, :execute, [])
    end

    invoke_task_callbacks(task, :after_hooks)
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

  alias Bootleg.Config.{ManageConfig, ArchiveConfig}

  @doc false
  @enforce_keys []
  defstruct [:archive, :manage]

  @doc """
  Creates a `Bootleg.Config` from the `Application` configuration (under the key `:bootleg`).

  The keys in the map should match the fields in the struct.
  """
  @type strategy :: {:strategy, [...]}
  @spec init([strategy]) :: %Bootleg.Config{}
  def init(options \\ []) do
    %__MODULE__{
      manage: ManageConfig.init(default_option(options, :manage)),
      archive: ArchiveConfig.init(default_option(options, :archive))
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
end
