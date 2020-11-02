alias Bootleg.{UI, Config, DSL}
use Bootleg.DSL

task :hot_downgrade do
  build_type = config({:build_type, "remote"})
  bootleg_env = config(:env)
  UI.info("Starting #{build_type} hot downgrade for #{bootleg_env} environment")
  invoke(:"#{build_type}_hot_downgrade")
end

before_task(:build, :verify_config)
