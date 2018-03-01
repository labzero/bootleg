defmodule Bootleg.Tasks.Other do
  @moduledoc false
  alias Bootleg.{Task, Config}
  use Task

  def load do
    use Config

    task :other do
      IO.puts("~~OTHER TASK~~")
    end

    before_task(:build, :other)
  end
end
