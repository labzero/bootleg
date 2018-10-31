defmodule Mix.Tasks.Bootleg do
  use Mix.Task
  alias Mix.Tasks.Help

  @shortdoc "Prints Bootleg help information"

  @moduledoc """
  Prints Bootleg tasks and their information.

      mix bootleg
  """

  @doc false
  def run(_args) do
    Application.ensure_all_started(:bootleg)
    Mix.shell().info("Bootleg v#{Application.spec(:bootleg, :vsn)}")
    Mix.shell().info("Simple deployment and server automation for Elixir.")
    Mix.shell().info("\nAvailable tasks:\n")
    Help.run(["--search", "bootleg."])
  end
end
