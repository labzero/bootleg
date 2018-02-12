use Bootleg.Config

task :deploy do
  app_role = Config.get_role(:app)

  if app_role.options[:release_workspace] do
    invoke :copy_deploy_release
  else
    invoke :upload_release
  end
  invoke :unpack_release
end

task :copy_deploy_release do
  app_role = Config.get_role(:app)
  app_name = Config.app()
  mix_env = config({:mix_env, "prod"})
  release_workspace = app_role.options[:release_workspace]
  workspace = app_role.options[:workspace]
  release = "#{Config.version()}.tar.gz"
  source_path = Path.join(release_workspace, release)
  dest_path = Path.join(workspace, "#{app_name}.tar.gz")
  UI.info("Copying release archive from release workspace")

  remote :app do
    "cp #{source_path} #{dest_path}"
  end
end

task :upload_release do
  remote_path = "#{Config.app}.tar.gz"
  local_archive_folder = "#{File.cwd!}/releases"
  local_path = Path.join(local_archive_folder, "#{Config.version}.tar.gz")
  UI.info "Uploading release archive"
  upload(:app, local_path, remote_path)
end

task :unpack_release do
  remote_path = "#{Config.app}.tar.gz"
  UI.info "Unpacking release archive"
  remote :app do
    "tar -zxvf #{remote_path}"
  end
  UI.info "Unpacked release archive"
end
