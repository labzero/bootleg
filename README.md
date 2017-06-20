# Bootleg

Simple deployment and server automation for Elixir.

**bootleg** is a simple set of commands that attempt to simplify building and deploying elixir applications. The goal of the project is to provide an extensible framework that can support many different deploy scenarios with one common set of commands.

Out of the box, bootleg provides remote build and remote server automation for you existing distillery releases.

## Installation

```elixir
def deps do
  [{:distillery, "~> 1.3",
   {:bootleg, "~> 0.1.0"}]
end
```

## Configuration

Configure Bootleg in the bootleg deploy config file:

```elixir
# config/deploy.exs
use Bootleg.Config

config build_at: "/usr/local/build/myapp/"
config deploy_to: "/var/www/#{app}" # default
config releases: "./releases"  # path to store releases
config scm: :git # only one supported right now. Need an alternative? Consider contributing!
```

```elixir
# config/deploy/production.exs - Create one for each environment you want to build and deploy to
role :build, "build.myapp.com", user, "build", port: "2222"
role :app, ["web1.myapp.com", "web2.myapp.com"], user: "admin"
role :db, ["admin@db1.myapp.com"]
```

## Roles

Actions in bootleg work against roles, sometimes referred to as a context. A
role, is simply a collection of hosts that are responsible for the
same function, for example building a release, or running your application.
Role names are unique so there can only be one of each defined, but
hosts can be grouped into one or more roles.

By defining roles, you are defining responsibility groups to cross cut your
host infrastructure. `:build` and
`:app` have inherent meaning to the default behavior of bootleg, but you may
also define more that you can later filter on when running commands inside a
bootleg hook. There is another built in role `:all` which will always include
all hosts assigned to any role.

Some features or extensions may require additional roles, for example if your
release needs to run Ecto migrations, you will need to assign the `:db`
role to one host.

To specify additional host connection options, a keyword list can be passed after
the hosts list. Additional connection options currently supported are:

1.  `user` # defaults to executing environment's current user
1.  `port` # default 22
1.  `timeout` # default :infinity

### More notes on roles

Some built in roles, or some roles defined by yet-to-be-written extensions, may
only allow ONE host to be defined and will warn or error if sent a list.

### Available roles

1. `:build` - Takes only one host. If a list is given, only the first hosts is
used and a warning may result. If no `:build` role is set, release package will
happen locally.
1. `:app` -  Takes a lists of hosts, or a string with one host.

### Future roles provided by some yet-to-be-written extensions?

1. `:db` - host on which to run migrations and other db related functions

## Versioning

Bootleg uses the application version as defined in `mix.exs`. Whether your application version is set here or comes from another source (e.g. [a VERSION file](https://gist.github.com/jeffweiss/9df547a4e472e3cf5bd3)), Bootleg requires it to be a parseable [Elixir.Version](https://hexdocs.pm/elixir/Version.html).

## Building and deploying a release

```console
mix bootleg.build production
mix bootleg.deploy production
mix bootleg.start production
```

Alternatively the above commands can be rolled into one with:

```console
mix bootleg.update production
```

## Admin Commands

bootleg has a set of commands to check up on your running nodes:

```console
mix bootleg.restart production  # Restarts a deployed release.
mix bootleg.start production      # Starts a deployed release.
mix bootleg.stop production      # Stops a deployed release.
mix bootleg.ping production      # Check status of running nodes
```

## Hooks and Events

[VERY MUCH A WIP]

Hooks may be defined by the user in order to perform additional (or exceptional)
operations before or after certain actions performed by bootleg.

Hooks are defined within `config/deploy.exs`. Hooks may be defined to trigger
before or after the following built-in events:

1. `build` - generation of a release package
1. `deploy` - deploy of a release package
1. `start` - starting of a release
1. `stop` - stopping of a release
1. `restart` - restarting of a release

Alternatively, custom events may be triggered inside your tasks. **Custom event
hooks are only available as after hooks**.

## `trigger`, `invoke`, `task` and events.

There are a few ways for custom code to be executed during the bootleg life
cycle. Before showing some examples, here's a quick glossary of the related
pieces.

 * `task <:identifier> do ... end` - Assign a block of code to the symbol provided as `:identifier`.
 This can then be executed by using the `invoke` macro.
 * `trigger <:event>` - Trigger a custom event with the identifier provided as `:event`
 * `invoke <:identifier>` - Execute the `task` code blocked identified by `:identifier`
 * `after <:event> do ... end` -  Respond to `:event` and execute the provided code block.

```elixir
use Bootleg.Task

before :build do
  IO.puts "Hello"
  trigger :custom_event
end

task :custom_task docs
  IO.puts "World"
end

after :custom_event do
  IO.puts "Elixir"
  invoke :custom_task
end
```

A shortened `before`/`after` syntax can be used to simply invoke a task directly from an event.

```elixir
task :clear_cache do
  {:ok, _} = remote do
    "rm -rf /tmp/cache"
  end
end

before :restart, do: :clear_cache
```

Alternatively:

```elixir
before :restart do
  {:ok, _output} = remote do
    "rm -rf /tmp/cache"
  end
end
```

### DSL Scratchpad

`remote do` and `remote :role do`

Execute shell commands on a remote server

```elixir
use Bootleg.Task

# basic - will run in context of role used by hook
{:ok, output} = remote do
  "echo hello"
end

# select role
remote :app do
  "ls"
end

# multi line
remote :app do
  "touch ~/file.txt"
  "rm file.txt"
end
```

```
{:ok, output} = success
{:error, output} = error

output = [
          {host, output, exit_status},
          {host, output, exit_status},
          ...
         ]
```

`task`

```elixir
use Bootleg.Task

task :example_task do
  IO.puts "local commands in elixir"
  remote do
    "echo remote commands inside remote blocks"
  end
  remote :app do
    "echo more than one remote block is fine"
  end
end

task :invoke_something do
  invoke :example_task
end

before `deploy` do: :invoke_something
```

## Help

If something goes wrong, retry with the `--verbose` option. 
For detailed information about the bootleg commands and their options, try `mix bootleg help <command>`.

## Examples

Build a release and deploy it to your production hosts:

```sh
mix bootleg.build
mix bootleg.deploy
mix bootleg.start
```

Or execute the above steps with a single command:

```sh
mix bootleg.update production
```

# run ecto migrations manually:

```sh
mix bootleg.migrate
```
-----

## Contributing

We welcome everyone to contribute to Bootleg and help us tackle existing issues!

Use the [issue tracker][issues] for bug reports or feature requests.
Open a [pull request][pulls] when you are ready to contribute.

If you are planning to contribute documentation, please check
[the best practices for writing documentation][writing-docs].


## LICENSE

Bootleg source code is released under the MIT License.
Check the [LICENSE](LICENSE) file for more information.

  [issues]: https://github.com/labzero/bootleg/issues
  [pulls]: https://github.com/labzero/bootleg/pulls
  [writing-docs]: http://elixir-lang.org/docs/stable/elixir/writing-documentation.html



