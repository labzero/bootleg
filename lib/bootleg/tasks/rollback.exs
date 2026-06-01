alias Bootleg.{Config, UI}
use Bootleg.DSL

task :rollback do
  app = Config.app()

  remote :app do
    "test $(ls -1d releases/*/ 2>/dev/null | wc -l) -ge 2 || (echo 'No previous release to roll back to' && exit 1)"
    "ls -1dt releases/*/ | tail -2 | head -1 | xargs -I{} ln -sfn {} current"
  end

  UI.info("⏪ #{app} rolled back")
end
