
# Configuration

Create and configure Bootleg's `config/deploy.exs` file:

```elixir
# config/deploy.exs
use Bootleg.DSL

role :build, "build.example.com", user, "build", port: 2222, workspace: "/tmp/build/myapp"
role :app, ["web1.example.com", "web2.myapp.com"], user: "admin", workspace: "/var/www/myapp"
```

## Environments

Bootleg has its own concept of environments, which is analogous to but different from `MIX_ENV`. Bootleg environments
are used if you have multiple clusters that you deploy your code to, such as a QA or staging cluster, in addition to
your `production` cluster. Your main Bootleg config still goes in `config/deploy.exs`, and environment specific details
goes in `config/deploy/your_bootleg_env.exs`. The selected environment config file gets loaded immediately after
`config/deploy.exs`. To invoke a Bootleg command with a specific environment, simply pass it as the first argument to
any bootleg Mix command.

For example, say you have both a `production` and a `staging` cluster. Your configuration might look like:

```elixir
# config/deploy.exs
use Bootleg.DSL

task :my_nifty_thing do
  Some.jazz()
end

after_task :deploy, :my_nifty_thing

role :build, "build.example.com", user, "build", port: 2222, workspace: "/tmp/build/myapp"
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
it would be `mix bootleg.update production`, or just `mix bootleg.update` (the default environment is `production`).

It is not a requirement that you define an environment file for each environment, but you will get a warning if
a specific environment file can't be found. It is strongly encouraged to have an environment file per environment.

## The `config` macro

The `config` macro can be used to get and set arbitrary key value pairs for use within Bootleg.

There are a few config settings that are directly used within Bootleg itself, they can be overwritten if needed, but can generally be left alone.

```elixir
config :app, :myapp
config :env, :staging # sets/overrides the bootleg environment
config :ex_path, "/path/to/project" # Path to the project. Default is current directory.
config :build_type, "local" # build releases locally without a `:build` role, (default `"remote"`)
config :refspec, "develop" # Set a git branch used for the build. Default is "master"
config :version, "1.2.3"
```

Any additional `config` settings can be set the same way and then looked up later with `config/1`.

```elixir
  use Bootleg.DSL
  config :foo, :bar

  # local_foo will be :bar
  local_foo = config :foo

  # local_foo will be :bar still, as :foo already has a value
  local_foo = config {:foo, :car}

  # local_hello will be :world, as :hello has not been defined yet
  local_hello = config {:hello, :world}

  config :hello, nil
  # local_hello will be nil, as :hello has a value of nil now
  local_hello = config {:hello, :world}

```