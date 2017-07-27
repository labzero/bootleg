defmodule Bootleg.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using args do
    quote do
      unless unquote(args)[:async] do
        setup do
          Bootleg.Config.Agent.wait_cleanup()
        end
      end
    end
  end
end
