defmodule Bootleg.Tasks do
  @moduledoc false
  alias Bootleg.{Config, UI}

  @path_deploy_config ["config", "deploy.exs"]
  @path_env_configs ["config", "deploy"]
  def path_deploy_config, do: @path_deploy_config
  def path_env_configs, do: @path_env_configs

  def load_tasks do
    use Config

    tasks_path = Path.join(__DIR__, "tasks")

    load_bootleg_tasks(tasks_path)

    load_third_party()

    Config.load(Path.join(@path_deploy_config))

    env_config_path =
      [@path_env_configs, ["#{Config.env()}.exs"]]
      |> List.flatten()
      |> Path.join()

    unless :ok == Config.load(env_config_path) do
      UI.warn(
        "You are running in the `#{Config.env()}` bootleg " <>
          "environment but there is no configuration defined for that environment. " <>
          "Create one at `#{env_config_path}` if you want to do additional " <> "customization."
      )
    end

    :ok
  end

  @doc false
  @spec parse_env_task([binary]) :: {nil, nil} | {nil, atom} | {binary, atom}
  def parse_env_task(args) when args == [], do: {nil, nil}

  def parse_env_task(args) when is_list(args) do
    args
    |> List.first()
    |> env_available?()
    |> case do
      true ->
        [env | args] = args
        pop_env_task(env, args)

      false ->
        pop_env_task(nil, args)
    end
  end

  @doc false
  @spec pop_env_task(binary, [binary]) :: {nil, nil} | {nil, atom} | {binary, atom}
  defp pop_env_task(env, args) when args == [] do
    {env, nil}
  end

  defp pop_env_task(env, args) do
    {env, String.to_atom(hd(args))}
  end

  @doc false
  @spec env_available?(atom) :: boolean
  def env_available?(env) when is_atom(env) do
    Enum.member?(available_envs(), Atom.to_string(env))
  end

  @doc false
  @spec env_available?(binary) :: boolean
  def env_available?(env) when is_binary(env) do
    Enum.member?(available_envs(), env)
  end

  @doc false
  @spec available_envs() :: [binary]
  defp available_envs do
    [@path_env_configs, "*.exs"]
    |> List.flatten()
    |> Path.join()
    |> Path.wildcard()
    |> Enum.map(&Path.basename(&1, ".exs"))
  end

  defp load_third_party do
    Enum.each(list_third_party(), fn mod ->
      mod.load()
    end)
  end

  defp load_bootleg_tasks(path) do
    path
    |> File.ls!()
    |> Enum.map(&Path.join(path, &1))
    |> Enum.each(fn x ->
      if File.dir?(x) do
        load_bootleg_tasks(x)
      else
        load_bootleg_task(x)
      end
    end)
  end

  defp load_bootleg_task(file) do
    Code.eval_string(File.read!(file), [], %{__ENV__ | line: 1, file: file})
  end

  @prefix "Elixir.Bootleg.Tasks."
  @suffix ".beam"
  @prefix_size byte_size(@prefix)
  @suffix_size byte_size(@suffix)

  defp list_third_party do
    :code.get_path()
    |> Enum.map(fn dir ->
      case File.ls(dir) do
        {:ok, files} -> files
        {:error, _} -> []
      end
    end)
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map(fn file ->
      segment_size = byte_size(file) - (@prefix_size + @suffix_size)

      case file do
        <<@prefix, task::binary-size(segment_size), @suffix>> ->
          task_module = :"#{@prefix}#{task}"

          Code.ensure_loaded?(task_module) && :erlang.function_exported(task_module, :load, 0) &&
            task_module

        _ ->
          false
      end
    end)
    |> Enum.filter(fn v -> v end)
  end
end
