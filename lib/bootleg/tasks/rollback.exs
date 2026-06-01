alias Bootleg.{Config, UI}
use Bootleg.DSL

task :rollback do
  app = Config.app()

  #
  # Check to make sure there are at least 2 releases so that there is one to roll
  # back to.
  # Then, get the second to last directory and roll back to there.
  # Finally, delete the rolledback release.
  #
  remote :app do
    "test $(ls -1d releases/*/ 2>/dev/null | wc -l) -ge 2 || (echo 'No previous release to roll back to' && exit 1)"
    "ls -1dtr releases/*/ | tail -2 | head -1 | xargs -I{} ln -sfn {} current"
    "ls -1dtr releases/*/ | tail -1 | xargs -I{} rm -rf {}"
    "touch --reference current/bin/#{app} current/bin/#{app}"
  end

  UI.info("⏪ #{app} rolled back")
end
