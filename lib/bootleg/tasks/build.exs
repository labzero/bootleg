alias Bootleg.{UI, Config}
use Bootleg.Config

task :build do
  Bootleg.Strategies.Build.Distillery.build()
end

task :generate_release do
  UI.info "Generating release"
  mix_env = Bootleg.Config.get_config(:mix_env, "prod")
  remote :build do
    "MIX_ENV=#{mix_env} mix release"
  end
end

task :compile do
  mix_env = Bootleg.Config.get_config(:mix_env, "prod")
  UI.info "Compiling remote build"
  remote :build do
    "MIX_ENV=#{mix_env} mix deps.compile"
    "MIX_ENV=#{mix_env} mix compile"
  end
end
