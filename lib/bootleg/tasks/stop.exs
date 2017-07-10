use Bootleg.Config

task :stop do
  config = Bootleg.config()

  strategy = Config.strategy(config, :manage)

  config
  |> strategy.init()
  |> strategy.stop(config)
  :ok
end
