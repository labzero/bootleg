defmodule Bootleg.TestCase do
  @moduledoc false
  defmacro __using__(args) do
    quote bind_quoted: binding() do
      use ExUnit.Case, args

      unless args[:async] do
        setup do
          Bootleg.Config.Agent.wait_cleanup()
        end
      end
    end
  end
end
