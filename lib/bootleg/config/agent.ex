defmodule Bootleg.Config.Agent do
  @moduledoc false

  alias Bootleg.Tasks

  @typep data :: keyword

  @spec start_link() :: {:ok, pid}
  def start_link do
    state_fn = fn ->
      [roles: [], config: [], before_hooks: [], after_hooks: [], next_hook_number: 0]
    end
    case Agent.start_link(state_fn, name: Bootleg.Config.Agent) do
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:ok, pid} ->
        wait_cleanup()
        launch_monitor()
        Tasks.load_tasks
        {:ok, pid}
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

  @spec wait_cleanup() :: :ok
  def wait_cleanup do
    if Process.whereis(:"Bootleg.Config.Agent.monitor") do
      Process.sleep(10)
      wait_cleanup()
    end
    :ok
  end

  @doc false
  @spec agent_monitor(pid) :: :ok
  def agent_monitor(parent_pid) do
    ref = Process.monitor(Bootleg.Config.Agent)
    Process.register(self(), :"Bootleg.Config.Agent.monitor")
    send(parent_pid, {:monitor_up, self()})
    receive do
      {:DOWN, ^ref, :process, _pid, _reason} ->
        Enum.each(:code.all_loaded(), fn {module, _file} ->
          if String.starts_with?(Atom.to_string(module), "Elixir.Bootleg.Tasks.DynamicTasks") do
            unload_code(module)
          end
        end)
        Process.unregister(:"Bootleg.Config.Agent.monitor")
    end
  end

  defp unload_code(module) do
    :code.purge(module)
    :code.delete(module)
  end

  defp launch_monitor do
    if Process.whereis(Bootleg.Config.Agent) do
      pid = Process.spawn(__MODULE__, :agent_monitor, [self()], [])
      receive do
        {:monitor_up, ^pid} -> :ok
      end
    end
  end

end
