alias Bootleg.{Config, UI}
use Bootleg.DSL

task :local_build do
  invoke(:local_compile)
  invoke(:local_generate_release)
  invoke(:copy_release)
end

task :local_compile do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, File.cwd!()})

  UI.info("Building locally with mix env #{mix_env}...")

  commands = [
    ["mix", ["local.rebar", "--force"]],
    ["mix", ["local.hex", "--if-missing", "--force"]],
    ["mix", ["deps.get", "--only=#{mix_env}"]],
    ["mix", ["do", "clean,", "compile", "--force"]]
  ]

  File.cd!(source_path, fn ->
    Enum.each(commands, fn [c, args] ->
      UI.info("[local] #{c} " <> Enum.join(args, " "))
      System.cmd(c, args, env: [{"MIX_ENV", mix_env}], into: IO.stream(:stdio, :line))
    end)
  end)
end

task :local_generate_release do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, File.cwd!()})
  release_args = config({:release_args, []})
  app_name = Config.app()

  UI.info("Generating release...")

  File.cd!(source_path, fn ->
    UI.info("[local] mix release " <> Enum.join(release_args, " "))

    System.cmd("mix", ["release"] ++ release_args,
      env: [{"MIX_ENV", mix_env}],
      into: IO.stream(:stdio, :line)
    )

    rel_dir = Path.join(source_path, "_build/#{mix_env}/rel")
    UI.info("[local] tar -czvf #{app_name}.tar.gz #{app_name}/")

    System.cmd("tar", ["-czvf", "#{app_name}.tar.gz", "#{app_name}/"],
      cd: rel_dir,
      into: IO.stream(:stdio, :line)
    )
  end)
end
