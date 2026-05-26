alias Bootleg.{Config, UI}
use Bootleg.DSL

task :start do
  remote :app do
    "bin/#{Config.app()} start"
  end

  UI.info("#{Config.app()} started")
  :ok
end
