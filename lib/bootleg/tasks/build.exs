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
  Bootleg.Strategies.Build.Distillery.build()
end

before_task :build, :verify_config

task :generate_release do
  UI.info "Generating release"
  mix_env = Keyword.get(Config.config(), :mix_env, "prod")
  remote :build do
    "MIX_ENV=#{mix_env} mix release"
  end
end

task :compile do
  mix_env = Keyword.get(Config.config(), :mix_env, "prod")
  UI.info "Compiling remote build"
  remote :build do
    "MIX_ENV=#{mix_env} mix deps.compile"
    "MIX_ENV=#{mix_env} mix compile"
  end
end

task :clean do
  locations = config()
    |> Keyword.get(:clean_locations, ["*"])
    |> List.wrap
    |> Enum.join(" ")
  if locations != "" do
    remote :build do
      "rm -rvf #{locations}"
    end
  end
end
