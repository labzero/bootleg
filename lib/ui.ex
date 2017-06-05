defmodule Bootleg.UI do
  @moduledoc ""

  @doc """
  Simple wrapper around IO.puts
  """
  def puts(text) do
    IO.puts text
  end

  @doc """
  Allow specifying detail level of output for later use.
  """
  def puts(:debug, _text), do: nil
  def puts(_level, text), do: puts(text)

  @doc """
  Output an impending upload operation.
  """
  def puts_upload(context, local_path, remote_path) do
    Enum.each(context.hosts, fn(host) ->
      [:bright, :green]
        ++ ["[" <> String.pad_trailing(host.name, 10) <> "] "]
        ++ [:reset, :yellow, "UPLOAD", " "]
        ++ [:reset, Path.relative_to_cwd(local_path)]
        ++ [:reset, :yellow, " -> "]
        ++ [:reset, Path.join(context.pwd, remote_path)]
      |> Bunt.puts()
    end)
  end

  @doc """
  Output an impending download operation.
  """
  def puts_download(context, remote_path, local_path) do
    Enum.each(context.hosts, fn(host) ->
      [:bright, :green]
        ++ ["[" <> String.pad_trailing(host.name, 10) <> "] "]
        ++ [:reset, :yellow, "DOWNLOAD", " "]
        ++ [:reset, Path.join(context.pwd, remote_path)]
        ++ [:reset, :yellow, " -> "]
        ++ [:reset, Path.relative_to_cwd(local_path)]
      |> Bunt.puts()
    end)
  end

  @doc """
  Output a command destined for one or more servers in an SSHKit context.
  """
  def puts_send(%SSHKit.Context{} = context, command) do
    Enum.each(context.hosts, fn(host) ->
      puts_send host, command
    end)
  end

  @doc """
  Output a command destined for a single SSHKit host.
  """
  def puts_send(%SSHKit.Host{} = host, command) do
    prefix = "[" <> String.pad_trailing(host.name, 10) <> "] "
    Bunt.puts [:bright, :green, prefix, :reset, command]
  end

  @doc """
  Any SSH calls using contexts will return a list of output tuples.
  """
  def puts_recv(outputs) when is_list(outputs) do
    Enum.each(outputs, &puts_recv/1)
  end

  @doc """
  Individually handle output tuple.
  """
  def puts_recv(output) when is_tuple(output) do
    case output do
      {:ok, [stdout: out], _status, host} -> split_received_lines(host, out)
      {:ok, [normal: out], _status, host} -> split_received_lines(host, out)
    end
  end

  @doc """
  Convenience function when wanting to output as if we'd received something
  from a particular set of hosts, e.g. a git+ssh output.
  """
  def puts_recv(%SSHKit.Context{} = context, output) when is_binary(output) do
    Enum.each(context.hosts, &puts_recv(&1, output))
  end

  @doc """
  Convenience function when wanting to output as if we'd received something
  from a particular host, e.g. a git+ssh output.
  """
  def puts_recv(%SSHKit.Host{} = host, output) when is_binary(output) do
    split_received_lines(host, output)
  end

  defp split_received_lines(%SSHKit.Host{} = host, text) do
    prefix = "[" <> String.pad_trailing(host.name, 10) <> "] "
    text
    |> String.split(["\r\n", "\n"])
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.map(&([:reset, :bright, :blue, prefix, :reset, &1]))
    |> drop_last_line()
    |> Enum.intersperse("\n")
    |> Bunt.puts
  end

  defp drop_last_line(lines) do
    case length(lines) < 2 do
      true  -> lines
      false -> Enum.drop(lines, -1)
    end
  end
end
