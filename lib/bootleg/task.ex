defmodule Bootleg.Task do
  @moduledoc """
  Bootleg supports automatic discovery of tasks found in your dependencies, or your project itself.

  To define a task that will automatically be loaded, define a new module in `Bootleg.Tasks`, and
  `use Bootleg.Task`, passing along a block containing Bootleg DSL commands. Tasks defined in this
  manner will be automatically loaded immediately after the core Bootleg tasks are loaded, and before
  `config/deploy.exs`. This is the recommended way to write tasks that you intend to share with
  others.

  ```
  defmodule Bootleg.Tasks.Example do
    use Bootleg.Task do
      task :example do
        IO.puts "Hello!"
      end

      before_task :build, :example
    end
  end
  ```

  Technically speaking, any module in the namespace `Bootleg.Tasks` that exports a `load/0` function will
  be discovered and executed by Bootleg automatically. This usage is not recommended unless you need to
  do work before `use Bootleg.DSL`.

  ```
  defmodule Bootleg.Tasks.Other do
    use Bootleg.Task
    def load do

      task :other do
        IO.puts "World?"
      end
    end
  end
  ```

  These tasks can be packaged and distributed via hex packages, or you can make your own specific to your
  application.

  """

  @doc """
  A task needs to implement `load` which receives no arguments. Return values are ignored.

  If you use the block version of `use Bootleg.Task`, this callback will be generated for you.
  """
  @callback load() :: any

  alias Bootleg.{UI, DSL}

  defmacro __using__(task_def) do
    quote do
      unless String.starts_with?(Atom.to_string(__MODULE__), "Elixir.Bootleg.Tasks.") do
        UI.warn(
          "You seem to be trying to define a Bootleg task, but your module is not in the " <>
            "`Bootleg.Tasks` namespace. Your task will not be loaded automatically."
        )
      end

      def load do
        use DSL

        unquote(task_def)
      end

      defoverridable load: 0
    end
  end
end
