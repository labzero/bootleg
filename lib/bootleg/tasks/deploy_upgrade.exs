alias Bootleg.{UI, Config, DSL}
use Bootleg.DSL

task :deploy_upgrade do
  app_role = Config.get_role(:app)

  if app_role.options[:release_workspace] do
    invoke(:copy_deploy_release_upgrade)
  else
    invoke(:upload_release_upgrade)
  end

  invoke(:unpack_release_upgrade)
end

task :copy_deploy_release_upgrade do
  app_role = Config.get_role(:app)
  release_workspace = app_role.options[:release_workspace]
  release = "#{Config.version()}.tar.gz"
  source_path = Path.join(release_workspace, release)
  dest_path = "#{Config.app()}.tar.gz"

  UI.info("Copying release archive from release upgrade workspace")

  remote :app do
    "cp #{source_path} #{dest_path}"
  end
end

task :upload_release_upgrade do
  remote_path = "#{Config.app()}.tar.gz"
  local_archive_folder = "#{File.cwd!()}/releases"
  local_path = Path.join(local_archive_folder, "#{Config.version()}.tar.gz")
  UI.info("Uploading release upgrade archive")
  upload(:app, local_path, remote_path)
end

task :unpack_release_upgrade do
  remote_path = "#{Config.app()}.tar.gz"
  remote_dest = "#{Config.version()}/#{Config.app()}.tar.gz"

  UI.info("Unpacking release upgrade archive")

  remote :app do
    "tar -zxvf #{remote_path}"
    "cp #{remote_path} releases/#{remote_dest}"
  end

  UI.info("Unpacked release upgrade archive")
end
