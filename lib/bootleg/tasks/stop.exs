alias Bootleg.{UI, Config}
use Bootleg.DSL

task :stop do
  app_name = Config.app()

  remote :app, cd: "current" do
    "bin/#{app_name} stop"
  end

  UI.info("#{app_name} stopped")
  :ok
end
