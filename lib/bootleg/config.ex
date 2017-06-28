defmodule Bootleg.Config do
  @doc false

  defmacro __using__(_) do
    quote do
      import Bootleg.Config, only: [role: 2, role: 3, config: 2, config: 0, before_task: 2,
        after_task: 2, invoke: 1, task: 2]
      {:ok, agent} = Bootleg.Config.Agent.start_link
      # var!(config_agent, Bootleg.Config) = agent
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

  defp add_callback(task, position, do: block) do
    hook_number = Bootleg.Config.Agent.increment(:next_hook_number)
    module_name = String.to_atom("Bootleg.Config.DynamicCallbacks." <>
      String.capitalize("#{position}") <> String.capitalize("#{task}") <>
      "#{hook_number}")
    quote do
      defmodule unquote(module_name) do
        def execute, do: unquote(block)
        hook_list_name = :"#{unquote(position)}_hooks"
        hooks = Keyword.get(Bootleg.Config.Agent.get(hook_list_name), unquote(task), [])
        Bootleg.Config.Agent.merge(hook_list_name, unquote(task), hooks ++
          [[unquote(module_name), :execute]])
      end
    end
  end

  defmacro before_task(task, do: block) when is_atom(task) do
    add_callback(task, :before, do: block)
  end

  defmacro after_task(task, do: block) when is_atom(task) do
    add_callback(task, :after, do: block)
  end

  defmacro task(task, do: block) when is_atom(task) do
    module_name = :"Bootleg.Config.DynamicTasks.#{String.capitalize("#{task}")}"
    quote do
      defmodule unquote(module_name) do
        def execute, do: unquote(block)
      end
    end
  end

  defp invoke_task_callbacks(task, agent_key) do
    agent_key
    |> Bootleg.Config.Agent.get()
    |> Keyword.get(task, [])
    |> Enum.each(fn([module, fnref]) -> apply(module, fnref, []) end)
  end

  def invoke(task) when is_atom(task) do
    invoke_task_callbacks(task, :before_hooks)

    module_name = :"Bootleg.Config.DynamicTasks.#{String.capitalize("#{task}")}"
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
