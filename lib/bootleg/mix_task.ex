defmodule Bootleg.MixTask do
  @moduledoc "Extends `Mix.Task` to provide Bootleg specific bootstrapping."
  alias Bootleg.Config

  defmacro __using__(task) do
    quote do
      use Mix.Task

      @spec run(OptionParser.argv) :: :ok
      if is_atom(unquote(task)) && unquote(task) do
        def run(args) do
          Config.env(List.first(args) || :production)
          use Config

          invoke unquote(task)
        end
      else
        def run(args) do
          Config.env(List.first(args) || :production)
          :ok
        end
      end

      defoverridable [run: 1]
    end
  end
end
