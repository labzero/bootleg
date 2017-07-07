use Bootleg.Config

task :ping do
  config = Bootleg.config()

  strategy = Config.strategy(config, :manage)
  project = Bootleg.project()

  config
  |> strategy.init(project)
  |> strategy.ping(config, project)
  :ok
end
