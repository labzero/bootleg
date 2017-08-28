defmodule Bootleg.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate
  alias Bootleg.UI

  setup tags do
    verbosity = Map.get(tags, :ui_verbosity, :silent)
    current_verbosity = UI.verbosity
    if current_verbosity != verbosity do
      Application.put_env(:bootleg, :verbosity, verbosity)
      on_exit fn -> Application.put_env(:bootleg, :verbosity, current_verbosity) end
    end

    :ok
  end

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
