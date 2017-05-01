defmodule Bootleg.SSH do
    @moduledoc "Provides SSH related tools for use in `Bootleg.Strategies`."

  alias SSHKit.SSH.ClientKeyAPI
  alias SSHKit.SCP
  
  def start, do: :ssh.start()

  def connect(host, user, identity_file) do
    with {:ok, identity} <- File.open(identity_file),
      cb = ClientKeyAPI.with_options(identity: identity),
      {:ok, conn} <- SSHKit.SSH.connect(host, [connect_timeout: 5000, key_cb: cb, user: user]) do
      conn
    else
      {_, msg} -> raise "Error: #{msg}"
    end
  end

  def run(conn, cmd, working_directory \\ ".") do
    IO.puts " -> $ #{cmd}" 
    SSHKit.SSH.run(conn, build_cmd(cmd, working_directory))
  end     

  def run!(conn, cmd, working_directory \\ ".")

  def run!(conn, cmd, working_directory) when is_list(cmd) do
    Enum.map(cmd, fn c -> run!(conn, c, working_directory) end)        
  end

  def run!(conn, cmd, working_directory) do
    case run(conn, build_cmd(cmd, working_directory)) do      
      {:ok, output, 0} -> {:ok, output}
      {:ok, output, status} -> raise format_error(cmd, output, status)  
    end
  end

  def download(conn, remote_path, local_path) do
    IO.puts " -> downloading #{remote_path} --> #{local_path}"
    case SCP.download(conn, remote_path, local_path) do
      :ok -> :ok
      {_, msg} -> raise "SCP download error: #{inspect msg}"
    end
  end  

  def upload(conn, local_path, remote_path, options \\ []) do
    IO.puts " -> uploading #{local_path} --> #{remote_path}"
    case SCP.upload(conn, remote_path, local_path) do
      :ok -> :ok
      {_, msg} -> raise "SCP upload error #{inspect msg}"
    end
  end  

  defp build_cmd(cmd, working_directory), do: "set -e;cd #{working_directory};#{cmd}"

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