alias Bootleg.{UI, Config}
use Bootleg.Config

task :ping do
  remote :app do
    "bin/#{Config.app()} ping"
  end

  :ok
end
