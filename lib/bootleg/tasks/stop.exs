alias Bootleg.{Config, UI}
use Bootleg.DSL

task :stop do
  app_name = Config.app()

  remote :app do
    "current/bin/#{app_name} stop"
  end

  UI.info("#{app_name} stopped")
  :ok
end
