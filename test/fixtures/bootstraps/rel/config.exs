# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
["rel", "plugins", "*.exs"]
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
  # This sets the default release built by `mix distillery.release`
  default_release: :default,
  # This sets the default environment used by `mix distillery.release`
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
  set(cookie: :"Xlr3[j$4lk$rp7[n*h7}s7{kTT_Ng}mGsrzI;L.hWY7Eg)$m[gHrc};!T::f;Aj5")
end

environment :prod do
  set(include_erts: true)
  set(include_src: false)
  set(cookie: :"l0Qe@8dHJa1LODI)k3WwFCG`@%BR|MJzS5UNH_f8xIN`u1(]i1G|{*6OZqt1?C_X")
end

# You may define one or more releases in this file. If you have not set a
# default release, or selected one when running `mix distillery.release`,
# the first release in the file will be used by default

release :bootstraps do
  set(version: current_version(:bootstraps))

  set(
    applications: [
      :runtime_tools
    ]
  )
end
