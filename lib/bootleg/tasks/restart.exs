use Bootleg.Config

task :restart do
  alias Bootleg.Strategies.Manage.Distillery
  Distillery.init()
  |> Distillery.restart()
  :ok
end
