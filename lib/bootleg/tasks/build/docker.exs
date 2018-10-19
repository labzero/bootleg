alias Bootleg.{UI, Config}
use Bootleg.DSL

task :docker_build do
  invoke(:docker_compile)
  invoke(:docker_copy_release)
end

task :docker_compile do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, File.cwd!()})
  docker_image = config(:docker_build_image)
  docker_mount = config({:docker_build_mount, "#{source_path}:/opt/build"})
  docker_run_options = config({:docker_build_opts, []})

  UI.info("Building in image \"#{docker_image}\" with mix env #{mix_env}...")

  commands = [
    ["mix", ["local.rebar", "--force"]],
    ["mix", ["local.hex", "--if-missing", "--force"]],
    ["mix", ["deps.get", "--only=#{mix_env}"]],
    ["mix", ["do", "clean,", "compile", "--force"]],
    ["mix", ["release", "--quiet"]]
  ]

  docker_args =
    [
      "run",
      "-v",
      docker_mount,
      "--rm",
      "-t",
      "-e",
      "MIX_ENV=#{mix_env}"
    ] ++ docker_run_options ++ [docker_image]

  IO.inspect docker_args
  UI.info("Docker command prefix:\n  " <> Enum.join(docker_args, " "))

  Enum.each(commands, fn [c, args] ->
    UI.info("[docker] #{c} " <> Enum.join(args, " "))

    System.cmd(
      "docker",
      docker_args ++ [c | args],
      into: IO.stream(:stdio, :line)
    )
  end)
end

task :docker_copy_release do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, File.cwd!()})
  app_name = Config.app()
  app_version = Config.version()

  archive_path =
    Path.join(
      source_path,
      "_build/#{mix_env}/rel/#{app_name}/releases/#{app_version}/#{app_name}.tar.gz"
    )

  local_archive_folder = Path.join([File.cwd!(), "releases"])
  File.mkdir_p!(local_archive_folder)
  File.cp!(archive_path, Path.join(local_archive_folder, "#{app_version}.tar.gz"))

  UI.info("Saved: releases/#{app_version}.tar.gz")
end
