alias Bootleg.{Config, DSL, UI}
use Bootleg.DSL

task :verify_config do
  if Config.app() == nil || Config.version() == nil do
    raise "Error: app or version to deploy is not set.\n" <>
            "Usually these are automatically picked up from Mix.Project.\n" <>
            "If this is an umbrella app, you must set these in your deploy.exs, e.g.:\n" <>
            "# config(:app, :myapp)\n" <> "# config(:version, \"0.0.1\")"
  end
end

task :build do
  build_type = config({:build_type, "remote"})
  bootleg_env = config(:env)
  UI.info("Starting #{build_type} build for #{bootleg_env} environment")
  invoke(:"#{build_type}_verify_config")
  invoke(:"#{build_type}_build")
end

task :copy_release do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, File.cwd!()})
  app_name = Config.app()
  app_version = Config.version()

  archive_path =
    Path.join(
      source_path,
      "_build/#{mix_env}/rel/#{app_name}.tar.gz"
    )

  local_archive_folder = Path.join([File.cwd!(), "releases"])
  File.mkdir_p!(local_archive_folder)
  File.cp!(archive_path, Path.join(local_archive_folder, "#{app_version}.tar.gz"))

  UI.info("Saved: releases/#{app_version}.tar.gz")
end

before_task(:build, :verify_config)
