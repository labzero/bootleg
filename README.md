# Bootleg

**Bootleg** is a simple set of commands that attempt to simplify building and deploying elixir applications. The goal of the project is to provide an extensible framework that can support many different deploy scenarios with one common set of commands.

Out of the box, Bootleg provides remote build and remote server automation for your existing [Distillery](https://github.com/bitwalker/distillery) releases.

## Installation

```elixir
def deps do
  [{:distillery, "~> 1.3",
   {:bootleg, "~> 0.1.0"}]
end
```

## Quick Start

### Configure your release parameters

```elixir
# config/deploy.exs
use Bootleg.Config

role :build, "your-build-server.local", user: "develop", password: "bu1ldm3", workspace "/some/build/workspace"
role :app, ["web1", "web2", "web3"], user: "admin", password: "d3pl0y", workspace "/var/myapp"
```

### build and deploy

```sh
$ mix bootleg.build
$ mix bootleg.deploy
$ mix bootleg.start
```

also see: [Phoenix support](#phoenix-support)

## Configuration

Create and configure Bootleg's `config/deploy.exs` file:

```elixir
# config/deploy.exs
use Bootleg.Config

role :build, "build.example.com", user, "build", port: "2222", workspace: "/tmp/build/myapp"
role :app, ["web1.example.com", "web2.myapp.com"], user: "admin", workspace: "/var/www/myapp"
```

## Roles

Actions in Bootleg are paired with roles, which are simply a collection of hosts that are responsible for the same function, for example building a release, archiving a release, or executing commands against a running application.

Role names are unique so there can only be one of each defined, but hosts can be grouped into one or more roles. Roles can be declared repeatedly to provide a different set of options to different sets of hosts.

By defining roles, you are defining responsibility groups to cross cut your host infrastructure. The `build` and
`app` roles have inherent meaning to the default behavior of Bootleg, but you may also define more that you can later filter on when running commands inside a bootleg hook. There is another built in role `:all` which will always include
all hosts assigned to any role. `:all` is only available via `remote/2`.

Some features or extensions may require additional roles, for example if your
release needs to run Ecto migrations, you will need to assign the `:db`
role to one host.

### Role and host options

Options are set on roles and on hosts based on the order in which the roles are defined. Some are used internally
by bootleg:

  * `workspace` - remote path specifying where to perform a build or push a deploy (default `.`)
  * `user` - ssh username (default to local user)
  * `password` - ssh password
  * `identity` - file path of an SSH private key identify file
  * `port` - ssh port (default `22`)

#### Examples

```elixir
role :app, ["host1", "host2"], user: "deploy", identity: "/home/deploy/.ssh/deploy_key.priv"
role :app, ["host2"], port: 2222
```
> In this example, two hosts are declared for the `app` role, both as the user *deploy* but only *host2* will use the non-default port of *2222*.

```elixir
role :db, ["db.example.com", "db2.example.com"], user: "datadog"
role :db, "db.example.com", primary: true
```
> In this example, two hosts are declared for the `db` role but the first will receive a host-specific option for being the primary. Host options can be arbitrarily named and targeted by tasks.

```elixir
role :balancer, ["lb1.example.com", "lb2.example.com"], banana: "boat"
role :balancer, "lb3.example.com"
```
> In this example, two load balancers are configured with a host-specific option of *banana*. The `balancer` role itself also receives the role-specific option of *banana*. A third balancer is then configured without any specific host options.


#### SSH options

If you include any common `:ssh.connect` options they will not be included in role or host options and will only be used when establishing SSH connections (exception: *user* is always passed to role and hosts due to its relevance to source code management).

Supported SSH options include:

* user
* port
* timeout
* recv_timeout

> Refer to `Bootleg.SSH.supported_options/0` for the complete list of supported options, and [:ssh.connect](http://erlang.org/doc/man/ssh.html#connect-2) for more information.

### Role restrictions

Bootleg extensions may impose restrictions on certain roles, such as restricting them to a certain number of hosts. See the extension documentation for more information.

### Roles provided by Bootleg

* `build` - Takes only one host. If a list is given, only the first hosts is
used and a warning may result. If this role isn't set the release packaging will be done locally.
* `app` -  Takes a lists of hosts, or a string with one host.

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

## Hooks

Hooks may be defined by the user in order to perform additional (or exceptional)
operations before or after certain actions performed by bootleg.

Hooks are defined within `config/deploy.exs`. Hooks may be defined to trigger
before or after a task. The following tasks are provided by bootleg:

1. `build` - build process for creating a release package
  1. `compile` - compilation of your project
  2. `generate_release` - generation of the release package
2. `deploy` - deploy of a release package
3. `start` - starting of a release
4. `stop` - stopping of a release
5. `restart` - restarting of a release
6. `ping` - check connectivity to a deployed app

Hooks can be defined for any task (built-in or user defined), even ones that do not exist. This can be used
to create an "event" that you want to respond to, but has no real "implementation".

To register a hook, use:

 * `before_task <:task> do ... end` - Before `task` executes, execute the provided code block.
 * `after_task <:task> do ... end` - After `task` executes, execute the provided code block.

For example:

```elixir
use Bootleg.Config

before_task :build do
  IO.puts "Starting build..."
end

after_task :deploy do
  MyAPM.notify_deploy()
end
```

You can define multiple hooks for a task, and they will be executed in the order they are defined. For example:

```elixir
use Bootleg.Config

before_task :start do
  IO.puts "This may take a bit"
end

after_task :start do
  IO.puts "Started app!"
end

before_task :start do
  IO.puts "Starting app!"
end
```

would result in:

```
$ mix bootleg.build
This may take a bit
Starting app!
...
Started app!
$
```

## `invoke` and `task`

There are a few ways for custom code to be executed during the bootleg life
cycle. Before showing some examples, here's a quick glossary of the related
pieces.

 * `task <:identifier> do ... end` - Assign a block of code to the atom provided as `:identifier`.
   This can then be executed by using the `invoke` macro.
 * `invoke <:identifier>` - Execute the `task` code blocked identified by `:identifier`, as well as
   any before/after hooks.

**NOTE:** Invoking an undefined task is not an error and any registered hooks will still be executed.

```elixir
use Bootleg.Config

before_task :build do
  IO.puts "Hello"
  invoke :custom_event
end

task :custom_task do
  IO.puts "World"
end

after_task :custom_event do
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

before_task :restart, do: :clear_cache
```

Alternatively:

```elixir
before_task :restart do
  {:ok, _output} = remote do
    "rm -rf /tmp/cache"
  end
end
```

## `remote`

The workhorse of the `bootleg` DSL is `remote`: it executes shell commands on remote servers and returns
the results. It takes a role and a block of commands to execute. The commands are executed on all servers
belonging to the role, and raises an `SSHError` if an error is encountered.

```elixir
use Bootleg.Config

# basic
remote :app do
  "echo hello"
end

# multi line
remote :app do
  "touch ~/file.txt"
  "rm file.txt"
end

# getting the result
[{:ok, [stdout: output], _, _}] = remote :app do
  "ls -la"
end

# raises an SSHError
remote :app do
  "false"
end
```

## Phoenix Support

Bootleg builds elixir apps, if your application has extra steps required make use of the hooks
system to add additional functionality. A common case is for building assets for Phoenix
applications. To build phoenix assets during your build, define an after hook handler for the
`:compile` task and place it inside your `config/deploy.exs`.

```elixir
after_task :compile do
  remote :build do
    "[ -f package.json ] && npm install || true"
    "[ -f brunch-config.js ] && [ -d node_modules ] && ./node_modules/brunch/bin/brunch b -p || true"
    "[ -d deps/phoenix ] && mix phoenix.digest || true"
  end
end
```

## Help

If something goes wrong, retry with the `--verbose` option.
For detailed information about the bootleg commands and their options, try `mix bootleg help <command>`.

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



