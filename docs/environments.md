# Environments

Bootleg has its own concept of environments, which is analogous to but different from `MIX_ENV`. Bootleg environments can be used if you have multiple clusters that you deploy your code to, such as a QA or staging cluster, in addition to
your production cluster.

## Configuration structure

If you bootstrapped your config as detailed in the [Installing](installing.md#set-up-bootleg) section the following files should already exist:

- `config/deploy.exs`
- `config/deploy/production.exs`

Your main Bootleg config still goes in `config/deploy.exs`, and environment-specific details
belong in the `deploy` subfolder, e.g. `config/deploy/acme.exs`.

## Specifying a Bootleg environment

To invoke a Bootleg command with a specific environment, simply pass it as the first argument to
any bootleg Mix command. That environment's config file will be loaded immediately after
`config/deploy.exs`.

For example, say you have both a `production` and a `staging` cluster. Your configuration might look like:

```elixir
# config/deploy.exs
use Bootleg.DSL

role :build, "build.example.com", user: "build", workspace: "/tmp/build/myapp"
```

```elixir
# config/deploy/production.exs
use Bootleg.DSL

role :app, ["web1.example.com", "web2.example.com"], user: "admin", workspace: "/var/www/myapp"
```

```elixir
# config/deploy/staging.exs
use Bootleg.DSL

role :app, ["stage1.example.com", "stage2.example.com"], user: "admin", workspace: "/var/www/myapp"
```

Then if you wanted to update staging, you would `mix bootleg.update staging`. If you wanted to update production,
it would be `mix bootleg.update production`, or just `mix bootleg.update` (the default environment is `production`, though this can be changed - see below).

It is not a requirement that you define an environment file for each environment, but you will get a warning if
a specific environment file can't be found. It is strongly encouraged to have a separate environment file for each environment.

## Internal config options

Bootleg has several built-in configuration options. These can be overridden if needed, but can generally be left alone.

```elixir
# config/deploy.exs
use Bootleg.DSL

config :app, :myapp
config :env, :staging # sets/overrides the bootleg environment
config :ex_path, "/path/to/project" # Path to the project. Default is current directory.
config :build_type, "local" # build releases locally without a `:build` role, (default `"remote"`)
config :refspec, "develop" # Set a git branch used for the build. Default is "master"
config :version, "1.2.3"
config :build_type, :remote # :remote, :local, or :docker
# config :build_image, "alpine"
# config :deploy_image, "bitwalker/alpine-elixir"
```

The config macro is used here to set internally-used options, but you can also use it via `config/1` and `config/2` to read and set your own arbitrary key-value pairs. See [Config Macro](config_macro.md) for more information.
