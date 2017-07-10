use Bootleg.Config

task :restart do
  config = Bootleg.config()

  strategy = Config.strategy(config, :manage)

  config
  |> strategy.init()
  |> strategy.restart(config)
  :ok
end
