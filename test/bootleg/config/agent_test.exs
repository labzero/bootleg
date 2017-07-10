defmodule Bootleg.Config.AgentTest do
  use ExUnit.Case, async: false
  alias Bootleg.Config.Agent

  test "stores values for retrieval" do
    {:ok, _} = Agent.start_link
    assert Agent.get(:config) == []

    Agent.put(:config, [key: :value, key2: :value])
    assert Agent.get(:config) == [key: :value, key2: :value]

    Agent.merge(:config, :foo, :bar)
    assert Agent.get(:config) == [key: :value, key2: :value, foo: :bar]
  end

  test "startlink/0 ignores 'already started' errors" do
    Agent.start_link
    assert {:ok, _} = Agent.start_link
  end
end
