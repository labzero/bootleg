defmodule Mix.Tasks.Bootleg.Invoke do
  use Bootleg.MixTask
  alias Bootleg.{UI, Config}

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

    case parse_env(args) do
      {nil, args} ->
        invoke String.to_atom(hd(args))
      {env, args} ->
        Config.env(env)
        invoke String.to_atom(hd(args))
    end
  end

  defp parse_env(args) do
    args
    |> List.first()
    |> Config.env_available?()
    |> case do
      true ->
        [env | args] = args
        {env, args}
      false ->
        {nil, args}
      end
  end
end
