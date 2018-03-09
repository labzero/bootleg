defmodule Bootleg.Tasks.Other do
  @moduledoc false
  alias Bootleg.{Task, DSL}
  use Task

  def load do
    use DSL

    task :other do
      IO.puts("~~OTHER TASK~~")
    end

    before_task(:build, :other)
  end
end
