defmodule RemoteCommandError do
  defexception [:message, :status, :output]

  def exception([cmd, output, status] = a) do
    msg = "Command exited with non-zero status (#{status})\n"
      <> format("cmd", cmd)
      <> cond_format("stdout", :normal, output)
      <> cond_format("stderr", :stderr, output)

    %RemoteCommandError{message: msg, status: status, output: output}
  end

  @padding 8
  defp format(key, value) do
    String.pad_leading(key, @padding)
      <> ": "
      <> String.trim_trailing(value)
      <> "\n"
  end

  defp cond_format(key, atom, output) do
    case List.keymember?(output, atom, 0) do
      true -> format(key, output[atom])
      _ -> ""
    end
  end
end

defmodule Bootleg.SSH do
  @moduledoc "Provides SSH related tools for use in `Bootleg.Strategies`."

  alias SSHKit.SSH.ClientKeyAPI

  def start, do: :ssh.start()

  def connect(hosts, user, identity_file \\ nil, workspace \\ ".") do
      hosts
      |> List.wrap
      |> Enum.map(
        fn(host) ->
          %SSHKit.Host{name: host, options: ssh_opts(user, identity_file)}
        end)
      |> SSHKit.context
      |> SSHKit.pwd(workspace)
  end

  def run(conn, cmd, working_directory \\ nil) do
    IO.puts " -> $ #{cmd}"
    SSHKit.run(conn, build_cmd(cmd, working_directory))
  end

  def run!(conn, cmd, working_directory \\ nil)

  def run!(conn, cmd, working_directory) when is_list(cmd) do
    Enum.map(cmd, fn c -> run!(conn, c, working_directory) end)
  end

  def run!(conn, cmd, working_directory) do
    case run(conn, build_cmd(cmd, working_directory)) do
      [{:ok, output, 0}|_] = result -> result
      [{:ok, output, status}|_] ->
        raise RemoteCommandError, [cmd, output, status]
    end
  end

  def download(conn, remote_path, local_path) do
    IO.puts " -> downloading #{remote_path} --> #{local_path}"
    case SSHKit.download(conn, remote_path, as: local_path) do
      [:ok|_] -> :ok
      [{_, msg}|_] -> raise "SCP download error: #{inspect msg}"
    end
  end

  def upload(conn, local_path, remote_path) do
    IO.puts " -> uploading #{local_path} --> #{remote_path}"
    case SSHKit.upload(conn, local_path, as: remote_path) do
      [:ok|_] -> :ok
      [{_, msg}|_] -> raise "SCP upload error #{inspect msg}"
    end
  end

  defp ssh_opts(user, nil), do: Keyword.merge(default_opts(), [user: user])

  defp ssh_opts(user, identity_file) do
    case File.open(identity_file) do
      {:ok, identity} ->
        key_cb = ClientKeyAPI.with_options(identity: identity,
                                           accept_hosts: true)
        Keyword.merge(default_opts(), [user: user, key_cb: key_cb])
      {_, msg} -> raise "Error: #{msg}"
    end
  end

  defp build_cmd(cmd, working_directory), do: "set -e;cd #{working_directory};#{cmd}"

  defp default_opts do
    [
      connect_timeout: 5000,
    ]
  end
end
