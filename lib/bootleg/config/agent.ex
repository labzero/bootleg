defmodule Bootleg.Config.Agent do
  @moduledoc false

  @typep data :: keyword

  @spec start_link() :: {:ok, pid}
  def start_link do
    Agent.start_link(fn -> [roles: [], config: []] end, name: Bootleg.Config.Agent)
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

end
