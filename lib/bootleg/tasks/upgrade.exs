alias Bootleg.{Config, DSL}
use DSL

task :upgrade do
  invoke(:build_upgrade)
  invoke(:deploy_upgrade)
  invoke(:hot_upgrade)
end
