use Bootleg.Config

task :start do
  config = Bootleg.config()

  strategy = Config.strategy(config, :manage)
  project = Bootleg.project()

  config
  |> strategy.init(project)
  |> strategy.stop(config, project)
  :ok
end
