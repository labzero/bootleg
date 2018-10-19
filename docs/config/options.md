# Configuration options

Bootleg has several built-in configuration options. These can be overridden if needed, but can generally be left alone.

## Setting config options

## Internal config options


```elixir
# config/deploy.exs
use Bootleg.DSL

config :app, :myapp
config :env, :staging # sets/overrides the bootleg environment
config :ex_path, "/path/to/project" # Base path to the project. Default is current directory.
config :build_type, "local" # build releases locally without a `:build` role, (default `"remote"`)
config :refspec, "develop" # Set a git branch used for the build. Default is "master"
config :version, "1.2.3"
config :build_type, :remote # :remote, :local, or :docker
```

The config macro is used here to set internally-used options, but you can also use it via `config/1` and `config/2` to read and set your own arbitrary key-value pairs. See [Config Macro](config_macro.md) for more information.

