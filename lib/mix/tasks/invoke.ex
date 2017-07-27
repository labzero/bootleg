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

  def run([task | _]) do
    use Config

    invoke String.to_atom(task)
  end

end
