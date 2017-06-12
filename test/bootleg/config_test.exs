defmodule Bootleg.ConfigTest do
  use ExUnit.Case, async: true

  doctest Bootleg.Config

  defmacrop roles do
    quote do
      Bootleg.Config.Agent.get(var!(config_agent, Bootleg.Config), :roles)
    end
  end

  defmacrop agent do
    quote do
      var!(config_agent, Bootleg.Config)
    end
  end

  test "role/2" do
    use Bootleg.Config
    assert roles() == []

    role :build, "build.labzero.com"
    assert roles() == [build: "build.labzero.com"]
  end

  test "config/0" do
    use Bootleg.Config
    Bootleg.Config.Agent.put(agent(), :config, [foo: :bar])
    assert config() == [foo: :bar]
  end

  test "config/2" do
    # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
    use Bootleg.Config
    assert config() == []

    config :build_at, "some path"
    assert config() == [build_at: "some path"]
  end
end
