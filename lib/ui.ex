defmodule Bootleg.UI do
  @moduledoc """
  Functions for capturing application and server output and filtering against
  a configured verbosity level.
  """

  @verbosities [:error, :warning, :info, :debug]

  @doc """
  Simple wrapper around IO.puts
  """
  def puts(""), do: :ok

  def puts(text) do
    IO.puts(text)
  end

  @doc """
  Prints a message and prompts the user for input.
  Input will be consumed until Enter is pressed.
  """
  def prompt(message) do
    IO.gets(message <> " ")
  end

  @doc """
  Prints a message and asks the user if they want to proceed.
  The user must press Enter or type one of "y", "yes", "Y", "YES" or
  "Yes".
  """
  def yes?(message) do
    answer = IO.gets(message <> " [Yn] ")
    is_binary(answer) and String.trim(answer) in ["", "y", "Y", "yes", "YES", "Yes"]
  end

  @doc """
  Allow specifying output verbosity level
  """
  def puts(level, output, setting \\ nil) do
    case verbosity_includes(setting || verbosity(), level) do
      true -> puts(output)
      false -> nil
    end
  end

  @doc """
  Convenience methods
  """
  def debug(output, setting \\ nil) do
    puts(:debug, output, setting)
  end

  def warn(output, setting \\ nil) do
    puts(:warning, output, setting)
  end

  def info(output, setting \\ nil) do
    puts(:info, output, setting)
  end

  def error(output, setting \\ nil) do
    puts(:error, output, setting)
  end

  @doc """
  Get configured output verbosity and sanitize it for our uses.
  Defaults to :info
  """
  def verbosity(setting \\ nil) do
    validate_verbosity(setting || Application.get_env(:bootleg, :verbosity, :info))
  end

  defp validate_verbosity(verbosity) when verbosity in @verbosities, do: verbosity
  defp validate_verbosity(_), do: :info

  defp verbosity_includes(setting, _) when setting not in @verbosities, do: false
  defp verbosity_includes(_, level) when level not in @verbosities, do: false

  defp verbosity_includes(setting, level) do
    index = fn value -> Enum.find_index(@verbosities, &(&1 == value)) end
    index.(setting) >= index.(level)
  end

  ### SSH formatting functions

  @doc """
  Output an impending upload operation.
  """
  def puts_upload(%SSHKit.Context{} = context, local_path, remote_path) do
    Enum.each(context.hosts, fn host ->
      ([:reset, :bright, :green] ++
         ["[" <> String.pad_trailing(host.name, 10) <> "] "] ++
         [:reset, :yellow, "UPLOAD", " "] ++
         [:reset, Path.relative_to_cwd(local_path)] ++
         [:reset, :yellow, " -> "] ++ [:reset, Path.join(context.path, remote_path)] ++ ["\n"])
      |> IO.ANSI.format(output_coloring())
      |> IO.write()
    end)
  end

  @doc """
  Output an impending download operation.
  """
  def puts_download(%SSHKit.Context{} = context, remote_path, local_path) do
    Enum.each(context.hosts, fn host ->
      ([:reset, :bright, :green] ++
         ["[" <> String.pad_trailing(host.name, 10) <> "] "] ++
         [:reset, :yellow, "DOWNLOAD", " "] ++
         [:reset, Path.join(context.path, remote_path)] ++
         [:reset, :yellow, " -> "] ++ [:reset, Path.relative_to_cwd(local_path)] ++ ["\n"])
      |> IO.ANSI.format(output_coloring())
      |> IO.write()
    end)
  end

  @doc """
  Output a command destined for one or more servers in an SSHKit context.
  """
  def puts_send(%SSHKit.Context{} = context, command) do
    Enum.each(context.hosts, fn host ->
      puts_send(host, command)
    end)
  end

  @doc """
  Output a command destined for a single SSHKit host.
  """
  def puts_send(%SSHKit.Host{} = host, command) do
    prefix = "[" <> String.pad_trailing(host.name, 10) <> "] "

    [:reset, :bright, :green, prefix, :reset, command, "\n"]
    |> IO.ANSI.format(output_coloring())
    |> IO.write()
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
  from a particular set of hosts, e.g. git+ssh output.
  """
  def puts_recv(%SSHKit.Context{} = context, output) when is_binary(output) do
    Enum.each(context.hosts, &puts_recv(&1, output))
  end

  @doc """
  Convenience function when wanting to output as if we'd received something
  from a particular host, e.g. git+ssh output.
  """
  def puts_recv(%SSHKit.Host{} = host, output) when is_binary(output) do
    split_received_lines(host, output)
  end

  defp split_received_lines(%SSHKit.Host{} = host, text) do
    prefix = "[" <> String.pad_trailing(host.name, 10) <> "] "

    text
    |> String.split(["\r\n", "\n"])
    |> Enum.map(&format_line(&1, prefix))
    |> IO.ANSI.format(output_coloring())
    |> IO.write()
  end

  defp format_line(line, prefix) do
    [:reset, :bright, :blue, prefix, :reset, String.trim_trailing(line), "\n"]
  end

  @doc """
  Get configured output coloring enabled
  Defaults to true
  """
  def output_coloring do
    Application.get_env(:bootleg, :output_coloring, true)
  end
end
