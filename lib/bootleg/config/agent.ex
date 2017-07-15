defmodule Bootleg.Config.Agent do
  @moduledoc false

  @typep data :: keyword

  @spec start_link() :: {:ok, pid}
  def start_link do
    state_fn = fn ->
      [roles: [], config: [], before_hooks: [], after_hooks: [], next_hook_number: 0]
    end
    case Agent.start_link(state_fn, name: Bootleg.Config.Agent) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      val -> val
    end
  end

  @spec get(atom) :: data
  def get(name) do
    Agent.get(Bootleg.Config.Agent, &Keyword.get(&1, name))
  end

  @spec put(atom, data) :: :ok
  def put(name, data) do
    Agent.update(Bootleg.Config.Agent, &Keyword.put(&1, name, data))
  end

  @spec merge(atom, atom, any) :: :ok
  def merge(name, key, value) do
    put(name, Keyword.merge(get(name), [{key, value}]))
  end

  @spec increment(atom) :: integer()
  def increment(key) do
    Agent.get_and_update(Bootleg.Config.Agent, fn (state) ->
      {state[key], Keyword.put(state, key, state[key] + 1)}
    end)
  end

end
