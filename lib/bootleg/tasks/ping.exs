use Bootleg.Config

task :ping do
  config = Bootleg.config()

  strategy = Config.strategy(config, :manage)

  config
  |> strategy.init()
  |> strategy.ping(config)
  :ok
end
