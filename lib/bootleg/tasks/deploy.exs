use Bootleg.Config

task :deploy do
  Bootleg.Strategies.Deploy.Distillery.deploy(Bootleg.project())
end
