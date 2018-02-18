defmodule Mix.Tasks.Bootleg.Invoke do
  use Bootleg.MixTask
  alias Bootleg.{UI, Config, Tasks}

  @shortdoc "Calls an arbitrary Bootleg task"

  @moduledoc """
  #{@shortdoc}

  # Usage:

    * mix bootleg.invoke <:task>

  """

  def run([]) do
    UI.error "You must supply a task identifier as the first argument."
    System.halt(1)
  end

  def run(args) do
    use Config

    case parse_env_task(args) do
      {nil, task} ->
        invoke String.to_atom(task)
      {env, task} ->
        Config.env(env)
        invoke String.to_atom(task)
    end
  end

  defp parse_env_task(args) do
    args
    |> List.first()
    |> Tasks.env_available?()
    |> case do
      true ->
        [env | args] = args
        {env, hd(args)}
      false ->
        {nil, hd(args)}
      end
  end
end
