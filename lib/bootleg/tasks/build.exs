use Bootleg.Config

task :build do
  config = Bootleg.config()

  archiver = Bootleg.Config.strategy(config, :archive)

  {:ok, build_filename} = Bootleg.Strategies.Build.Distillery.build()

  unless archiver == false do
    archiver.archive(build_filename)
  end
end
