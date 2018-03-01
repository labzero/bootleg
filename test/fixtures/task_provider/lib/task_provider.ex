defmodule Bootleg.Tasks.Example do
  @moduledoc false
  use Bootleg.Task do
    task :example do
      IO.puts("~~EXAMPLE TASK~~")
    end

    before_task(:build, :example)
  end
end
