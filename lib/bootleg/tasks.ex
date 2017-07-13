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

    Config.load("config/deploy.exs")
    :ok
  end
end
