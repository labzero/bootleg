defmodule Bootleg.ConfigTest do
  use ExUnit.Case, async: true

  doctest Bootleg.Config

  defmacrop roles do
    quote do
      Bootleg.Config.Agent.get(var!(config_agent, Bootleg.Config), :roles)
    end
  end

  test "role/2" do
    use Bootleg.Config
    assert roles() == []

    role :build, "build.labzero.com"
    assert roles() == [build: "build.labzero.com"]
  end
end
