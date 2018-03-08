alias Bootleg.Config
use Bootleg.DSL

task :update do
  invoke(:build)
  invoke(:deploy)
  invoke(:stop_silent)
  invoke(:start)
end

task :stop_silent do
  nodetool = "bin/#{Config.app()}"

  remote :app do
    "#{nodetool} describe && (#{nodetool} stop || true)"
  end
end
