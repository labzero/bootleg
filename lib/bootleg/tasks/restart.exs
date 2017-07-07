use Bootleg.Config

task :restart do
  config = Bootleg.config()

  strategy = Config.strategy(config, :manage)
  project = Bootleg.project()

  config
  |> strategy.init(project)
  |> strategy.restart(config, project)
  :ok
end
