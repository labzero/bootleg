alias Bootleg.{UI, Config}
use Bootleg.Config

task :stop do
  app_name = Config.app
  remote :app do
    "bin/#{app_name} stop"
  end
  UI.info "#{app_name} stopped"
  :ok
end
