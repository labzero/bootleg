defmodule Bootleg.Tasks do
  @moduledoc false
  alias Bootleg.{Config, Env}

  def load_tasks do
    load_bootleg_tasks(Path.join(__DIR__, "tasks"))
    load_third_party()
    Config.load(Env.deploy_config())
    Env.load(Config.env())

    :ok
  end

  @doc false
  @spec parse_env_task([binary]) :: {nil, nil} | {nil, atom} | {binary, atom}
  def parse_env_task(args) when args == [], do: {nil, nil}

  def parse_env_task(args) when is_list(args) do
    args
    |> List.first()
    |> Env.available?()
    |> case do
      true ->
        [env | args] = args
        pop_env_task(env, args)

      false ->
        pop_env_task(nil, args)
    end
  end

  @doc false
  @spec pop_env_task(any, [binary]) :: {nil, nil} | {nil, atom} | {binary, atom}
  defp pop_env_task(env, args) when args == [] do
    {env, nil}
  end

  defp pop_env_task(env, args) do
    {env, String.to_atom(hd(args))}
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
        Config.load(x)
      end
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
