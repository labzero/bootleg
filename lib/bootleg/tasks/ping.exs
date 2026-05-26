alias Bootleg.{Config, UI}
use Bootleg.DSL

task :ping do
  remote :app do
    "bin/#{Config.app()} ping"
  end

  :ok
end
