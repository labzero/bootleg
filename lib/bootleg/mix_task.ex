defmodule Bootleg.MixTask do
  @moduledoc "Extends `Mix.Task` to provide Bootleg specific bootstrapping."
  alias Bootleg.{Config, DSL, Tasks}

  defmacro __using__(task) do
    quote do
      use Mix.Task

      @spec run(OptionParser.argv()) :: :ok
      if is_atom(unquote(task)) && unquote(task) do
        def run(args) do
          {env, _} = Tasks.parse_env_task(args)

          if env do
            Config.env(env)
          end

          use DSL

          invoke(unquote(task))
        end
      else
        def run(args) do
          {env, _} = Tasks.parse_env_task(args)

          if env do
            Config.env(env)
          end

          :ok
        end
      end

      defoverridable run: 1
    end
  end
end
