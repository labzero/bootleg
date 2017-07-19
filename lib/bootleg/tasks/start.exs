use Bootleg.Config

task :start do
  alias Bootleg.Strategies.Manage.Distillery
  Distillery.init()
  |> Distillery.start()
  :ok
end
