defmodule Bootleg.SSH do
  @moduledoc "Provides SSH related tools for use in `Bootleg.Strategies`."

  alias SSHKit.{Context, SSH.ClientKeyAPI}
  alias SSHKit.Host, as: SSHKitHost
  alias SSHKit.SSH, as: SSHKitSSH
  alias Bootleg.{UI, Host, Role, Config}

  def init(role, options \\ [])
  def init(%Role{} = role, options) do
    role_options = Keyword.merge(role.options, [user: role.user])
    init(role.hosts, Keyword.merge(role_options, options))
  end

  def init(role_name, options) when is_atom(role_name) do
    init(Config.get_role(role_name), options)
  end

  def init(hosts, options) do
      workspace = Keyword.get(options, :workspace, ".")
      create_workspace = Keyword.get(options, :create_workspace, true)
      UI.puts "Creating remote context at '#{workspace}'"

      :ssh.start()

      hosts
      |> List.wrap
      |> Enum.map(&ssh_host_options/1)
      |> SSHKit.context
      |> validate_workspace(workspace, create_workspace)
  end

  def ssh_host_options(%Host{} = host) do
    sshkit_host = get_in(host, [Access.key!(:host)])
    sshkit_host_options = get_in(sshkit_host, [Access.key!(:options)])

    %SSHKitHost{sshkit_host | options: ssh_opts(sshkit_host_options)}
  end

  def run(context, cmd) do
    cmd = Context.build(context, cmd)

    run = fn host ->
      UI.puts_send host, cmd

      conn = case SSHKitSSH.connect(host.name, host.options) do
        {:ok, conn} -> conn
        {:error, err} -> raise SSHError, [err, host]
      end

      conn
      |> SSHKitSSH.run(cmd, fun: &capture(&1, &2, host))
      |> Tuple.append(host)
    end

    Enum.map(context.hosts, run)
  end

  defp validate_workspace(context, workspace, create_workspace)
  defp validate_workspace(context, workspace, false) do
    run!(context, "test -d #{workspace}")
    SSHKit.path context, workspace
  end
  defp validate_workspace(context, workspace, true) do
    run!(context, "mkdir -p #{workspace}")
    SSHKit.path context, workspace
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
    case SSHKit.download(conn, remote_path, as: local_path) do
      [:ok|_] -> :ok
      [{_, msg}|_] -> raise "SCP download error: #{inspect msg}"
    end
  end

  def upload(conn, local_path, remote_path) do
    UI.puts_upload conn, local_path, remote_path
    case SSHKit.upload(conn, local_path, as: remote_path) do
      [:ok|_] -> :ok
      [{_, msg}|_] -> raise "SCP upload error #{inspect msg}"
    end
  end

  def ssh_opts(options) do
    List.flatten(Enum.map(options, &ssh_opt/1))
  end

  def ssh_opt({:identity, nil}), do: []
  def ssh_opt({:identity, identity_file}) do
    case File.open(identity_file) do
      {:ok, identity} ->
        key_cb = ClientKeyAPI.with_options(identity: identity, accept_hosts: true)
        [{:key_cb, key_cb}, {:identity, identity_file}]
      {_, msg} -> raise "Error: #{msg}"
    end
  end

  def ssh_opt({_, nil}), do: []
  def ssh_opt(option), do: option

  @ssh_options ~w(user password port key_cb auth_methods connection_timeout id_string
    idle_time silently_accept_hosts user_dir timeout connection_timeout)a
  def supported_options do
    @ssh_options
  end
end
