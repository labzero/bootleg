alias Bootleg.{UI, Config}
use Bootleg.DSL

task :ping do
  remote :app do
    UI.error("TODO: Make this work?")
  end

  :ok
end
