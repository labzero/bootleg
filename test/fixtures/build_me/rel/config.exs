# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
["rel", "plugins", "*.exs"]
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
  # This sets the default release built by `mix release`
  default_release: :default,
  # This sets the default environment used by `mix release`
  default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html

# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set(dev_mode: true)
  set(include_erts: false)
  set(cookie: :"X4;[FrPc_I7ts,/Kv!b8/Ug]>_138CL/17Ars}Q!a>~32,X(p1Dd2|P]u}S:a`18")
end

environment :prod do
  set(include_erts: true)
  set(include_src: false)
  set(cookie: :"[7o)DJ]AnI4;eNDXgRk.%3$yjTi/J<r5EG%v>Y{7ACZZ>b7kl(,OL3.w;MsPyjk3")
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :build_me do
  set(version: current_version(:build_me))

  set(
    applications: [
      :runtime_tools
    ]
  )
end
