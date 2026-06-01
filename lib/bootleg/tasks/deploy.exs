alias Bootleg.{Config, UI}
use Bootleg.DSL

task :deploy do
  app_role = Config.get_role(:app)

  if app_role.options[:release_workspace] do
    invoke(:copy_deploy_release)
  else
    invoke(:upload_release)
  end

  invoke(:unpack_release)
end

task :copy_deploy_release do
  app_role = Config.get_role(:app)
  release_workspace = app_role.options[:release_workspace]
  release = "#{Config.version()}.tar.gz"
  source_path = Path.join(release_workspace, release)
  dest_path = "#{Config.app()}.tar.gz"

  UI.info("Copying release archive from release workspace")

  remote :app do
    "cp #{source_path} #{dest_path}"
  end
end

task :upload_release do
  remote_path = "#{Config.app()}.tar.gz"
  local_archive_folder = "#{File.cwd!()}/releases"
  tar_ball =
    "ls -t #{local_archive_folder} | head -1"
    |> System.shell()
    |> elem(0)
    |> String.trim_trailing()
  local_path = Path.join(local_archive_folder, tar_ball)
  UI.info("⚡ Uploading release archive #{tar_ball}")
  upload(:app, local_path, remote_path)
end

task :unpack_release do
  app = Config.app()
  remote_path = "#{app}.tar.gz"
  keep_releases = Config.get_role(:app).options[:keep_releases]
  UI.info("⚡ Unpacking release archive: #{remote_path}")

  remote :app do
    "mkdir -p releases/"
    "tar -zxf #{remote_path} -C releases/"
    "ls -td releases/*/ | head -1 | xargs -I{} ln -sfn {} current"
    "rm #{remote_path}"
    "touch --reference current/bin/#{app} current/bin/#{app}"
  end

  if keep_releases do
    remote :app do
      "ls -1dt releases/*/ | tail -n +#{keep_releases + 1} | xargs -I{} rm -rf {}"
    end
  end
end
