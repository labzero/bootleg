defmodule Bootleg.Config.Agent do
  @moduledoc false

  @typep data :: keyword

  @spec start_link() :: {:ok, pid}
  def start_link do
    Agent.start_link fn -> [roles: [], config: []] end
  end

  @spec get(pid, atom) :: data
  def get(agent, name) do
    Agent.get(agent, &Keyword.get(&1, name))
  end

  @spec put(pid, atom, data) :: :ok
  def put(agent, name, data) do
    Agent.update(agent, &Keyword.put(&1, name, data))
  end

  @spec merge(pid, atom, atom, any) :: :ok
  def merge(agent, name, key, value) do
    put(agent, name, Keyword.merge(get(agent, name), [{key, value}]))
  end

end
