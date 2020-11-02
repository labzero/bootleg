alias Bootleg.{UI, Config, DSL}
use Bootleg.DSL

task :build_upgrade do
  build_type = config({:build_type, "remote"})
  bootleg_env = config(:env)
  UI.info("Starting #{build_type} build for #{bootleg_env} environment")
  invoke(:"#{build_type}_verify_config")
  invoke(:"#{build_type}_build_upgrade")
end

before_task(:build, :verify_config)
