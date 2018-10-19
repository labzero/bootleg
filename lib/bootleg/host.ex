defmodule Bootleg.Host do
  @moduledoc false
  @enforce_keys [:host, :options]
  defstruct [:host, :options]

  def init(host, :docker) do
    %__MODULE__{
      host: nil,
      options: []
    }
  end

  def init(host, options) do
    IO.inspect options
    %__MODULE__{
      host: SSHKit.host(host),
      options: options
    }
  end

  def host_name(%__MODULE__{} = host) do
    get_in(host, [Access.key!(:host), Access.key!(:name)])
  end

  def option(%__MODULE__{} = host, option) when is_atom(option) do
    get_in(host, [Access.key!(:options), option])
  end

  def option(%__MODULE__{} = host, option, value) when is_atom(option) do
    put_in(host, [Access.key!(:options), option], value)
  end

  def combine_uniq(hosts) do
    do_combine_uniq(hosts, %{}, &host_id/1, [])
  end

  defp host_id(host) do
    {host_name(host), option(host, :port)}
  end

  defp do_combine_uniq([h | t], set, fun, acc) do
    value = fun.(h)

    case set do
      %{^value => true} -> do_combine_uniq(t, set, fun, Enum.map(acc, &combine_hosts(&1, h)))
      %{} -> do_combine_uniq(t, Map.put(set, value, true), fun, [h | acc])
    end
  end

  defp do_combine_uniq([], _set, _fun, acc) do
    :lists.reverse(acc)
  end

  defp combine_hosts(host1, host2) do
    if host_id(host1) == host_id(host2) do
      combine_host_options(host1, host2)
    else
      host1
    end
  end

  defp combine_host_options(host1, host2) do
    host_options = Keyword.merge(host1.options, host2.options)

    host1
    |> put_in([Access.key!(:options)], host_options)
  end
end

defimpl String.Chars, for: Bootleg.Host do
  def to_string(h), do: "Bootleg.Host: #{h.host.name}"
end
