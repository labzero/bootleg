defmodule Bootleg.Host do
  @moduledoc ""
  @enforce_keys [:host, :options]
  defstruct [:host, :options]

  def init(host, ssh_options, role_options) do
    %__MODULE__{
      host: SSHKit.host(host, ssh_options),
      options: role_options
    }
  end

  def host_name(%__MODULE__{} = host) do
    get_in(host, [Access.key!(:host), Access.key!(:name)])
  end

  def combine_uniq(hosts) do
    do_uniq_hosts(hosts, %{}, &host_name/1, [])
  end

  defp do_uniq_hosts([h | t], set, fun, acc) do
    value = fun.(h)
    case set do
      %{^value => true} -> do_uniq_hosts(t, set, fun, Enum.map(acc, &combine_hosts(&1, h)))
      %{} -> do_uniq_hosts(t, Map.put(set, value, true), fun, [h | acc])
    end
  end

  defp do_uniq_hosts([], _set, _fun, acc) do
    :lists.reverse(acc)
  end

  defp combine_hosts(host1, host2) do
    search_name = get_in host2, [Access.key!(:host), Access.key!(:name)]
    case get_in host1, [Access.key!(:host), Access.key!(:name)] do
      ^search_name -> combine_host_options host1, host2
      _ -> host1
    end
  end

  defp combine_host_options(host1, host2) do
    ssh_options = Keyword.merge(host1.host.options, host2.host.options)
    host_options = Keyword.merge(host1.options, host2.options)

    host1
    |> put_in([Access.key!(:host), Access.key!(:options)], ssh_options)
    |> put_in([Access.key!(:options)], host_options)
  end
end

defimpl String.Chars, for: Bootleg.Host do
  def to_string(host), do: "Host #{host.host.name}"
end
