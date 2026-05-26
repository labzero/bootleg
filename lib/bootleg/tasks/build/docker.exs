# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
alias Bootleg.{Config, UI}
use Bootleg.DSL

task :docker_verify_config do
  if config(:build_type) == :docker && !config(:docker_build_image) do
    raise "Docker builds require `docker_build_image` to be specified"
  end
end

task :docker_build do
  invoke(:docker_compile)
  invoke(:docker_generate_release)
  invoke(:copy_release)
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
    ["mix", ["do", "clean,", "compile", "--force"]]
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

  UI.debug("Docker command prefix:\n  " <> Enum.join(docker_args, " "))

  Enum.each(commands, fn [c, args] ->
    UI.info("[docker] #{c} " <> Enum.join(args, " "))

    {_stream, status} =
      System.cmd(
        "docker",
        docker_args ++ [c | args],
        into: IO.stream(:stdio, :line)
      )

    if status != 0, do: raise("Command returned non-zero exit status #{status}")
  end)
end

task :docker_generate_release do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, File.cwd!()})
  docker_image = config(:docker_build_image)
  docker_mount = config({:docker_build_mount, "#{source_path}:/opt/build"})
  docker_run_options = config({:docker_build_opts, []})
  release_args = config({:release_args, []})
  app_name = Config.app()

  UI.info("Generating release...")

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

  UI.debug("Docker command prefix:\n  " <> Enum.join(docker_args, " "))

  commands = [
    ["mix", ["release"] ++ release_args],
    ["bash", ["-c", "cd _build/#{mix_env}/rel && tar -czvf #{app_name}.tar.gz #{app_name}/"]]
  ]

  Enum.each(commands, fn [c, args] ->
    UI.info("[docker] #{c} " <> Enum.join(args, " "))

    {_stream, status} =
      System.cmd(
        "docker",
        docker_args ++ [c | args],
        into: IO.stream(:stdio, :line)
      )

    if status != 0, do: raise("Command returned non-zero exit status #{status}")
  end)
end
