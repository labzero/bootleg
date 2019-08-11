defmodule Bootleg.Config do
  @moduledoc """
    Configuration manager for Bootleg.
  """

  alias Mix.Project

  defmacro __using__(_) do
    quote do
      IO.warn(
        "`use Bootleg.Config` is deprecated; call `use Bootleg.DSL` instead.",
        Macro.Env.stacktrace(__ENV__)
      )

      import Bootleg.DSL,
        only: [
          role: 2,
          role: 3,
          config: 2,
          config: 1,
          config: 0,
          before_task: 2,
          after_task: 2,
          invoke: 1,
          task: 2,
          remote: 1,
          remote: 2,
          remote: 3,
          load: 1,
          upload: 3,
          download: 3
        ]
    end
  end

  @doc false
  @spec get_role(atom) :: %Bootleg.Role{} | nil
  def get_role(name) do
    case Keyword.get(Bootleg.Config.Agent.get(:roles), name) do
      nil -> raise "The \"#{name}\" role has not been defined, but a task is trying to use it!"
      role -> role
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
      true ->
        Code.eval_file(file)
        :ok

      false ->
        {:error, :enoent}
    end
  end

  @doc false
  @spec get_all() :: any
  def get_all do
    Bootleg.Config.Agent.get(:config)
  end

  @doc false
  @spec get_key(atom, any) :: any
  def get_key(key, default \\ nil) do
    Keyword.get(Bootleg.Config.Agent.get(:config), key, default)
  end

  @doc false
  @spec set_key(atom, any) :: any
  def set_key(key, value) do
    Bootleg.Config.Agent.merge(
      :config,
      key,
      value
    )
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
    unless Project.umbrella?() do
      val = Project.config()[prop]
      Bootleg.Config.Agent.merge(:config, prop, val)
      val
    else
      nil
    end
  end

  @doc false
  @spec env() :: any
  def env do
    get_key(:env, :production)
  end

  @doc false
  @spec env(any) :: :ok
  def env(env) do
    {:ok, _} = Bootleg.Config.Agent.start_link(env)
    set_key(:env, env)
  end
end
