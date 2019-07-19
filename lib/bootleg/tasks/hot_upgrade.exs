alias Bootleg.{UI, Config, DSL}
use Bootleg.DSL

task :hot_upgrade do
  build_type = config({:build_type, "remote"})
  bootleg_env = config(:env)
  UI.info("Starting #{build_type} hot upgrade for #{bootleg_env} environment")
  invoke(:"#{build_type}_hot_upgrade")
end

before_task(:build, :verify_config)
