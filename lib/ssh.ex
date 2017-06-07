defmodule Bootleg.SSH do
  @moduledoc "Provides SSH related tools for use in `Bootleg.Strategies`."

  alias SSHKit.{Host, Context, SSH.ClientKeyAPI}
  alias Bootleg.UI

  @runner Application.get_env(:bootleg, :sshkit) || SSHKit
  @local_options ~w(create_workspace)a

  def init(hosts, user, options \\ []) do
      workspace = Keyword.get(options, :workspace, ".")
      create_workspace = Keyword.get(options, :create_workspace, false)
      UI.puts "Creating remote context at '#{workspace}'"

      options = Enum.filter(options, &Enum.member?(@local_options, elem(&1, 0)) == false)
      :ssh.start()

      hosts
      |> List.wrap
      |> Enum.map(fn(host) -> %SSHKit.Host{name: host, options: ssh_opts(user, options)} end)
      |> SSHKit.context
      |> validate_workspace(workspace, create_workspace)
  end

  def run(context, cmd) do
    cmd = Context.build(context, cmd)

    run = fn host ->
      UI.puts_send host, cmd
      {:ok, conn} = @runner.SSH.connect(host.name, host.options)
      conn
      |> @runner.SSH.run(cmd, fun: &capture(&1, &2, host))
      |> Tuple.append(host)
    end

    Enum.map(context.hosts, run)
  end

  defp validate_workspace(context, workspace, create_workspace)
  defp validate_workspace(context, workspace, false) do
    run!(context, "test -d #{workspace}")
    SSHKit.pwd context, workspace
  end
  defp validate_workspace(context, workspace, true) do
    run!(context, "mkdir -p #{workspace}")
    SSHKit.pwd context, workspace
  end

  defp capture(message, state = {buffer, status}, host) do
    next = case message do
      {:data, _, 0, data} ->
        UI.puts_recv host, String.trim_trailing(data)
        {[{:stdout, data} | buffer], status}
      {:data, _, 1, data} -> {[{:stderr, data} | buffer], status}
      {:exit_status, _, code} -> {buffer, code}
      {:closed, _} -> {:ok, Enum.reverse(buffer), status}
      _ -> state
    end

    {:cont, next}
  end

  def run!(conn, command)

  def run!(conn, commands) when is_list(commands) do
    Enum.map(commands, fn c -> run!(conn, c) end)
  end

  def run!(conn, command) do
    conn
    |> run(command)
    |> Enum.map(&run_result(&1, command))
  end

  defp run_result({:ok, _, 0, _} = result, _), do: result
  defp run_result({:ok, output, status, host}, command) do
    raise SSHError, [command, output, status, host]
  end

  def download(conn, remote_path, local_path) do
    UI.puts_download conn, remote_path, local_path
    case @runner.download(conn, remote_path, as: local_path) do
      [:ok|_] -> :ok
      [{_, msg}|_] -> raise "SCP download error: #{inspect msg}"
    end
  end

  def upload(conn, local_path, remote_path) do
    UI.puts_upload conn, local_path, remote_path
    case @runner.upload(conn, local_path, as: remote_path) do
      [:ok|_] -> :ok
      [{_, msg}|_] -> raise "SCP upload error #{inspect msg}"
    end
  end

  defp ssh_opts(user, options) when is_list(options) do
    identity_file = Keyword.get(options, :identity, nil)
    case File.open(identity_file) do
      {:ok, identity} ->
        key_cb = ClientKeyAPI.with_options(identity: identity, accept_hosts: true)
        Keyword.merge(default_opts(), [user: user, key_cb: key_cb])
      {_, msg} -> raise "Error: #{msg}"
    end
  end

  defp ssh_opts(user, _), do: Keyword.merge(default_opts(), [user: user])

  defp default_opts do
    [
      connect_timeout: 5000,
    ]
  end
end
