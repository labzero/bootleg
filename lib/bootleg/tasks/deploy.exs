alias Bootleg.{UI, Config}
use Bootleg.DSL

task :deploy do
  app_role = Config.get_role(:app)
  invoke(:init_release)

  if app_role.options[:release_workspace] do
    invoke(:copy_deploy_release)
  else
    invoke(:upload_release)
  end

  invoke(:unpack_release)
  invoke(:publish_release)
  invoke(:cleanup)
end

task :init_release do
  today = DateTime.utc_now()

  release_vsn =
    [today.year, today.month, today.day, today.hour, today.minute, today.second]
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.pad_leading(&1, 2, "0"))
    |> Enum.join("")

  remote(:app, "mkdir -p releases/#{release_vsn}")

  config(:release_vsn, release_vsn)
end

task :copy_deploy_release do
  app_role = Config.get_role(:app)
  release_workspace = app_role.options[:release_workspace]
  release = "#{Config.version()}.tar.gz"
  source_path = Path.join(release_workspace, release)
  dest_path = Path.join("releases/#{config({:release_vsn, ""})}", "#{Config.app()}.tar.gz")

  UI.info("Copying release archive from release workspace")

  remote :app do
    "cp #{source_path} #{dest_path}"
  end
end

task :upload_release do
  remote_path = Path.join("releases/#{config({:release_vsn, ""})}", "#{Config.app()}.tar.gz")
  local_archive_folder = "#{File.cwd!()}/releases"
  local_path = Path.join(local_archive_folder, "#{Config.version()}.tar.gz")
  UI.info("Uploading release archive")
  upload(:app, local_path, remote_path)
end

task :unpack_release do
  remote_path = "#{Config.app()}.tar.gz"
  UI.info("Unpacking release archive")

  remote :app, cd: "releases/#{config({:release_vsn, ""})}" do
    "tar -zxvf #{remote_path}"
  end

  UI.info("Unpacked release archive")
end

task :publish_release do
  release = "releases/#{config({:release_vsn, ""})}"

  remote(:app) do
    "ln -s $(pwd)/#{release} $(pwd)/releases/current"
    "mv releases/current ."
  end

  UI.info("Release ready to restart")
end

task :cleanup do
  UI.info("Cleanup releases")
  [{:ok, [stdout: stdout], 0, _}] = remote(:app, "ls -x releases")
  releases = String.split(stdout)

  releases_count = config({:keep_releases, 3})

  if length(releases) > releases_count do
    remove_releases =
      (releases -- Enum.take(releases, -releases_count))
      |> Enum.reject(fn release ->
        release === config({:release_vsn, ""})
      end)

    directories =
      remove_releases
      |> Enum.map(fn release ->
        "releases/#{release}"
      end)

    directories_str = Enum.join(directories, " ")
    remote(:app, "rm -rf #{directories_str}")
  end
end
