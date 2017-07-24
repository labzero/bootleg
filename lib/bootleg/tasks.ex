defmodule Bootleg.Tasks do
  @moduledoc false
  alias Bootleg.Config

  def load_tasks do
    use Config

    tasks_path = Path.join(__DIR__, "tasks")
    parent_env = %{__ENV__ | line: 1}

    tasks_path
    |> File.ls!()
    |> Enum.map(fn (file) -> Path.join(tasks_path, file) end)
    |> Enum.map(fn (file) -> {File.read!(file), %{parent_env | file: file}} end)
    |> Enum.each(fn ({code, env}) -> Code.eval_string(code, [], env) end)

    load_third_party()

    Config.load("config/deploy.exs")
    :ok
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
    |> Enum.map(&File.ls!/1)
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
