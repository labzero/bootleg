alias Bootleg.{Config, DSL}
use Bootleg.DSL

task :verify_config do
  if Config.app() == nil || Config.version() == nil do
    raise "Error: app or version to deploy is not set.\n" <>
            "Usually these are automatically picked up from Mix.Project.\n" <>
            "If this is an umbrella app, you must set these in your deploy.exs, e.g.:\n" <>
            "# config(:app, :myapp)\n" <> "# config(:version, \"0.0.1\")"
  end

  if config(:build_type) == :docker && !config(:docker_image) do
    raise "Error: Docker builds require `docker_image` to be specified"
  end
end

task :build do
  build_type = config({:build_type, "remote"})
  invoke(:"#{build_type}_build")
end

before_task(:build, :verify_config)
