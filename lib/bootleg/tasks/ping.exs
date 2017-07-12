use Bootleg.Config

task :ping do
  alias Bootleg.Strategies.Manage.Distillery
  Distillery.init()
  |> Distillery.ping()
  :ok
end
