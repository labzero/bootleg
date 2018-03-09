alias Bootleg.{UI, Config}
use Bootleg.DSL

task :local_build do
  UI.info("Starting local build")
  invoke(:local_compile)
  invoke(:local_generate_release)
  invoke(:local_copy_release)
end

task :local_generate_release do
  UI.info("Generating release")
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, "."})

  File.cd!(source_path, fn ->
    System.cmd("mix", ["release"], env: [{"MIX_ENV", mix_env}], into: IO.stream(:stdio, :line))
  end)
end

task :local_compile do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, "."})
  UI.info("Compiling build")

  File.cd!(source_path, fn ->
    System.cmd(
      "mix",
      ["local.rebar", "--force"],
      env: [{"MIX_ENV", mix_env}],
      into: IO.stream(:stdio, :line)
    )

    System.cmd(
      "mix",
      ["local.hex", "--force"],
      env: [{"MIX_ENV", mix_env}],
      into: IO.stream(:stdio, :line)
    )

    System.cmd(
      "mix",
      ["deps.get", "--only=#{mix_env}"],
      env: [{"MIX_ENV", mix_env}],
      into: IO.stream(:stdio, :line)
    )

    System.cmd(
      "mix",
      ["deps.compile"],
      env: [{"MIX_ENV", mix_env}],
      into: IO.stream(:stdio, :line)
    )

    System.cmd("mix", ["compile"], env: [{"MIX_ENV", mix_env}], into: IO.stream(:stdio, :line))
  end)
end

task :local_copy_release do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, "."})
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
end
