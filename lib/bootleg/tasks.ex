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

    tasks_path
    |> File.ls!()
    |> Enum.map(fn (file) -> Path.join(tasks_path, file) end)
    |> Enum.map(fn (file) -> {File.read!(file), %{__ENV__ | line: 1, file: file}} end)
    |> Enum.each(fn ({code, env}) -> Code.eval_string(code, [], env) end)

    load_third_party()

    Config.load(Path.join(@path_deploy_config))

    env_config_path =
      [@path_env_configs, ["#{Config.env}.exs"]]
      |> List.flatten()
      |> Path.join()

    unless :ok == Config.load(env_config_path) do
      UI.warn("You are running in the `#{Config.env}` bootleg " <>
        "environment but there is no configuration defined for that environment. " <>
        "Create one at `#{env_config_path}` if you want to do additional " <>
        "customization.")
    end

    :ok
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
    |> List.flatten
    |> Enum.uniq
    |> Enum.map(fn file ->
      segment_size = byte_size(file) - (@prefix_size + @suffix_size)
      case file do
        <<@prefix, task::binary-size(segment_size), @suffix>> ->
          task_module = :"#{@prefix}#{task}"
          Code.ensure_loaded?(task_module) && :erlang.function_exported(task_module, :load, 0) &&
            task_module
        _ -> false
      end
    end)
    |> Enum.filter(fn v -> v end)
  end
end
