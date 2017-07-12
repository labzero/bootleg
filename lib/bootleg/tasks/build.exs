use Bootleg.Config

task :build do
  Bootleg.Strategies.Build.Distillery.build()
end
