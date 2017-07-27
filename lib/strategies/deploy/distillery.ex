defmodule Bootleg.Strategies.Deploy.Distillery do
  @moduledoc false

  alias Bootleg.{Config, UI, SSH}

  def deploy do
    deploy_release_archive(init())
    :ok
  end

  def init do
    SSH.init(:app)
  end

  defp deploy_release_archive(conn) do
    app_name = Config.app
    app_version = Config.version
    remote_path = "#{app_name}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{app_version}.tar.gz")

    UI.info "Uploading release archive"
    SSH.upload(conn, local_path, remote_path)

    unpack_cmd = "tar -zxvf #{remote_path}"
    SSH.run!(conn, unpack_cmd)
    UI.info "Unpacked release archive"
  end
end
