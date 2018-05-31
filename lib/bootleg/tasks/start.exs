alias Bootleg.{UI, Config}
use Bootleg.DSL

task :start do
  remote :app, cd: "current" do
    "bin/#{Config.app()} start"
  end

  UI.info("#{Config.app()} started")
  :ok
end
