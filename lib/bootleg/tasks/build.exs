use Bootleg.Config

task :build do
  config = Bootleg.config()

  archiver = Bootleg.Config.strategy(config, :archive)
  project = Bootleg.project()

  {:ok, build_filename} = Bootleg.Strategies.Build.Distillery.build(project)

  unless archiver == false do
    archiver.archive(project, build_filename)
  end
end
