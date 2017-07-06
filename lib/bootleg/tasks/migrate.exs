use Bootleg.Config

task :migrate do
  config = Bootleg.config()

  strategy = Config.strategy(config, :manage)
  project = Bootleg.project()

  config
  |> strategy.init(project)
  |> strategy.migrate(config, project)
  :ok
end
