defmodule Bootleg.Config do
  @moduledoc """
    Configuration manager for Bootleg.
  """

  alias Mix.Project

  defmacro __using__(_) do
    quote do
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
    Keyword.get(Bootleg.Config.Agent.get(:roles), name)
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
  @spec get_config(atom, any) :: any
  def get_config(key, default \\ nil) do
    Keyword.get(Bootleg.Config.Agent.get(:config), key, default)
  end

  @doc false
  @spec set_config(atom, any) :: any
  def set_config(key, value) do
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
    get_config(:env, :production)
  end

  @doc false
  @spec env(any) :: :ok
  def env(env) do
    {:ok, _} = Bootleg.Config.Agent.start_link(env)
    set_config(:env, env)
  end

end
