use Bootleg.Config

task :update do
  invoke :build
  invoke :deploy
  invoke :start
end
