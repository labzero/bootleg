defmodule Bootleg.Strategies.Deploy.RemoteSSH do
  @moduledoc ""

  @ssh Application.get_env(:bootleg, :ssh) || Bootleg.SSH

  alias Bootleg.Config
  alias Bootleg.DeployConfig
  alias Bootleg.SSH


  def deploy(%Config{version: version, app: app, deploy: %DeployConfig{workspace: workspace}} = config) do
    conn = init(config)
    deploy_release_archive(conn, workspace, app, version)
  end

  defp deploy_setup_script(workspace) do
      "
      set -e
      mkdir -p #{workspace}
      "
  end

  def init(%Config{deploy: %DeployConfig{identity: identity, workspace: workspace, host: host, user: user} = config}) do
    with {:ok, _} <- check_config(config),
         :ok <- @ssh.start() do       
          host 
          |> @ssh.connect(user, identity)
          |> @ssh.run!(deploy_setup_script(workspace))
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  defp check_config(%DeployConfig{} = config) do
    missing =  Enum.filter(~w(host user workspace), &(Map.get(config, &1, 0) == nil))
    if Enum.count(missing) > 0 do
      raise "RemoteSSH deploy strategy requires #{inspect Map.keys(missing)} to be set in the build configuration"
    end
    {:ok, config}        
  end

  defp deploy_release_archive(conn, workspace, app, version) do
    remote_path = "#{workspace}/#{app}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{app}-#{version}.tar.gz")

    IO.puts "Uploading release archive"
    IO.puts " <-  local: #{local_path}"
    IO.puts " -> remote: #{remote_path}"

    case @ssh.upload(conn, local_path, remote_path) do
      :ok -> conn
      {:error, msg} -> raise "Error: uploading of release archive failed: #{msg}"
    end
    unpack_cmd = "tar -zxvf #{remote_path}"
    @ssh.run!(conn, unpack_cmd, workspace)
    IO.puts "Unpacked release archive"
  end
end
