use Bootleg.Config

task :stop do
  alias Bootleg.Strategies.Manage.Distillery
  Distillery.init()
  |> Distillery.stop()
  :ok
end
