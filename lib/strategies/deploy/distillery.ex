defmodule Bootleg.Strategies.Deploy.Distillery do
  @moduledoc ""

  @ssh Application.get_env(:bootleg, :ssh, Bootleg.SSH)

  alias Bootleg.{Config, Config.DeployConfig, UI}

  @config_keys ~w(hosts user identity workspace)

  def deploy(%Config{version: version, app: app, deploy: %DeployConfig{}} = config) do
    conn = init(config)
    deploy_release_archive(conn, app, version)
  end

  def init(%Config{deploy: %DeployConfig{identity: identity, workspace: workspace, hosts: hosts, user: user} = config}) do
    with :ok <- Bootleg.check_config(config, @config_keys) do
      @ssh.init(hosts, user, identity: identity, workspace: workspace, create_workspace: true)
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  defp deploy_release_archive(conn, app, version) do
    remote_path = "#{app}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{version}.tar.gz")

    UI.info "Uploading release archive"
    @ssh.upload(conn, local_path, remote_path)

    unpack_cmd = "tar -zxvf #{remote_path}"
    @ssh.run!(conn, unpack_cmd)
    UI.info "Unpacked release archive"
  end
end
