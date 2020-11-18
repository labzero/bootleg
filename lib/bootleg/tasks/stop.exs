alias Bootleg.{UI, Config}
use Bootleg.DSL

task :stop do
  app_name = Config.app()

  remote :app do
    "sudo systemctl #{app_name} stop"
  end

  UI.info("#{app_name} stopped")
  :ok
end
