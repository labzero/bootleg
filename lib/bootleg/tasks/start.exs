use Bootleg.Config

task :start do
  config = Bootleg.config()

  strategy = Config.strategy(config, :manage)

  config
  |> strategy.init()
  |> strategy.start(config)
  :ok
end
