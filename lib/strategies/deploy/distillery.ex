defmodule Bootleg.Strategies.Deploy.Distillery do
  @moduledoc ""

  alias Bootleg.{Project, UI, SSH}

  def deploy(%Project{} = project) do
    project
    |> init
    |> deploy_release_archive(project)
    :ok
  end

  def init(%Project{} = _project) do
    SSH.init(:app, create_workspace: true)
  end

  defp deploy_release_archive(conn, %Project{} = project) do
    remote_path = "#{project.app_name}.tar.gz"
    local_archive_folder = "#{File.cwd!}/releases"
    local_path = Path.join(local_archive_folder, "#{project.app_version}.tar.gz")

    UI.info "Uploading release archive"
    SSH.upload(conn, local_path, remote_path)

    unpack_cmd = "tar -zxvf #{remote_path}"
    SSH.run!(conn, unpack_cmd)
    UI.info "Unpacked release archive"
  end
end
