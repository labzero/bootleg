alias Bootleg.{UI, Config}
use Bootleg.DSL

task :restart do
  remote :app do
    "sudo systemctl #{Config.app()} restart"
  end

  UI.info("#{Config.app()} restarted")
  :ok
end
