alias Bootleg.{UI, Config}
use Bootleg.Config

task :verify_config do
  if Config.app() == nil || Config.version() == nil do
    raise "Error: app or version to deploy is not set.\n"
     <> "Usually these are automatically picked up from Mix.Project.\n"
     <> "If this is an umbrella app, you must set these in your deploy.exs, e.g.:\n"
     <> "# config(:app, :myapp)\n"
     <> "# config(:version, \"0.0.1\")"
  end
end

task :build do
  if Config.config(:local_build) do
    invoke :local_build
  else
    invoke :remote_build
  end
end

before_task :build, :verify_config
