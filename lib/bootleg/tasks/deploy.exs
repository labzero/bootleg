use Bootleg.Config

task :deploy do
  invoke :upload_release
  invoke :unpack_release
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
