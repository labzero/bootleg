defmodule Bootleg.Config.AgentTest do
  use Bootleg.TestCase, async: false
  alias Bootleg.Config.Agent
  import ExUnit.CaptureIO

  test "stores values for retrieval" do
    {:ok, _} = Agent.start_link()
    assert Agent.get(:config) == [env: :production]

    Agent.put(:config, key: :value, key2: :value)
    assert Agent.get(:config) == [key: :value, key2: :value]

    Agent.merge(:config, :foo, :bar)
    assert Agent.get(:config) == [key: :value, key2: :value, foo: :bar]
  end

  test "start_link/0 ignores 'already started' errors" do
    Agent.start_link()
    assert {:ok, _} = Agent.start_link()
  end

  test "start_link/1 ignores 'already started' errors" do
    Agent.start_link()
    assert {:ok, _} = Agent.start_link(:foo)
  end

  test "start_link/0 sets the environment to `production`" do
    Agent.start_link()
    assert Agent.get(:config) == [env: :production]
  end

  test "start_link/1 sets the environment to the provided env" do
    capture_io(fn ->
      Agent.start_link(:bar)
    end)

    assert Agent.get(:config) == [env: :bar]
  end
end
