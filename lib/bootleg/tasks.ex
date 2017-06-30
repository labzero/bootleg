defmodule Bootleg.Tasks do
  @moduledoc false
  @on_load :load_tasks

  def load_tasks do
    use Bootleg.Config

    tasks_path = Path.join(__DIR__, "tasks")
    tasks_path
    |> File.ls!()
    |> Enum.map(fn (file) -> Path.join(tasks_path, file) end)
    |> Enum.map(&File.read!/1)
    |> Enum.each(fn (code) -> Code.eval_string(code, [], __ENV__) end)
  end
end
