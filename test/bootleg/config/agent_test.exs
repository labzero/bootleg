defmodule Bootleg.Config.AgentTest do
  use ExUnit.Case, async: true
  alias Bootleg.Config.Agent

  test "stores values for retrieval" do
    {:ok, agent} = Agent.start_link
    assert Agent.get(agent, :config) == []

    Agent.put(agent, :config, [key: :value, key2: :value])
    assert Agent.get(agent, :config) == [key: :value, key2: :value]

    Agent.merge(agent, :config, :foo, :bar)
    assert Agent.get(agent, :config) == [key: :value, key2: :value, foo: :bar]
  end
end
