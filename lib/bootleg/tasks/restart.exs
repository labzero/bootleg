alias Bootleg.{Config, UI}
use Bootleg.DSL

task :restart do
  remote :app do
    "bin/#{Config.app()} restart"
  end

  UI.info("#{Config.app()} restarted")
  :ok
end
