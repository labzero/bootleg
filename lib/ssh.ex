defmodule Bootleg.SSH do
  defstruct [:conn]

  alias SSHKit.{SSH.ClientKeyAPI, SCP}
  
  def start, do: :ssh.start() # does this belong somewhere else

  def connect(host, user, identity) do
    cb = ClientKeyAPI.with_options(identity: identity)
    case SSHKit.SSH.connect(host, [connect_timeout: 5000, key_cb: cb, user: user]) do
      {:ok, conn} -> %__MODULE__{conn: conn}
      {_, msg} -> raise "Error: #{msg}"
    end
  end

  def run(%__MODULE__{conn: conn} = ssh, cmd) do
    case SSHKit.SSH.run(conn, cmd) do
      {:ok, _, 0} -> ssh
      {:ok, output, status} -> raise format_error(cmd, output, status)      
    end
  end

  def download(%__MODULE__{conn: conn}, remote_path, local_path) do
    SCP.download(conn, remote_path, local_path)    
  end  

  def safe_run(%__MODULE__{} = ssh, working_directory, cmd) when is_list(cmd) do
    Enum.each(cmd, fn cmd ->
      safe_run(ssh, working_directory, cmd)
    end)
    ssh
  end

  def safe_run(%__MODULE__{} = ssh, working_directory, cmd) when is_binary(cmd) do
    IO.puts " -> $ #{cmd}"
    run(ssh, "set -e;cd #{working_directory};#{cmd}")      
  end

  defp format_error(cmd, output, status) do
    "Remote command exited with non-zero status (#{status})
         cmd: \"#{cmd}\"
      stderr: #{parse_output(output[:stderr])}
      stdout: #{parse_output(output[:normal])}
     "
  end

  defp parse_output(nil), do: ""
  defp parse_output(out) do
    String.trim_trailing(out)
  end  
end