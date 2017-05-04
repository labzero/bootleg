defmodule Bootleg.Strategies.Deploy.RemoteSSH do
  @moduledoc ""

  @ssh Application.get_env(:bootleg, :ssh) || Bootleg.SSH

  alias Bootleg.{Config, DeployConfig}

  @config_keys ~w(host user identity workspace)

  def deploy(%Config{version: version, app: app, deploy: %DeployConfig{}} = config) do
    conn = init(config)
    deploy_release_archive(conn, app, version)
  end

  def init(%Config{deploy: %DeployConfig{identity: identity, workspace: workspace, host: host, user: user} = config}) do
    with :ok <- Bootleg.check_config(config, @config_keys),
         :ok <- @ssh.start(),
         conn <- @ssh.connect(host, user, [identity: identity, workspace: workspace]) do
      conn
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  defp deploy_release_archive(conn, app, version) do
    remote_path = "#{app}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{version}.tar.gz")

    IO.puts "Uploading release archive"
    IO.puts " <-  local: #{local_path}"
    IO.puts " -> remote: #{remote_path}"

    @ssh.upload(conn, local_path, remote_path)

    unpack_cmd = "tar -zxvf #{remote_path}"
    @ssh.run!(conn, unpack_cmd)
    IO.puts "Unpacked release archive"
  end
end
