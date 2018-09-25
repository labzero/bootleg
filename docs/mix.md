
# Mix Tasks

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

Note that `bootleg.update` will stop any running nodes and then perform a cold start. The stop is performed with
the task `stop_silent`, which differs from `stop` in that it does not fail if the node is already stopped.

`bootleg.build` will clean the remote workspace prior to copying the code over, to ensure that any files left from
a previous build do not cause issues. The entire contents of the remote workspace are removed via `rm -rf *` from
the root of the workspace. You can configure this behavior by setting the config option `clean_locations`, which
takes a list of locations and passes them to `rm -rf` on the remote server. Relative paths will be interpreted relative
to the workspace, absolute paths will be treated as is. Warning: this means that `config :clean_locations, ["/"]` would
attempt to erase the entire root file system of your remote server. Be careful when altering `clean_locations` and never
use a privileged user on your build server.

## Admin Commands

Bootleg has a set of commands to check up on your running nodes:

```console
mix bootleg.restart production   # Restarts a deployed release.
mix bootleg.start production     # Starts a deployed release.
mix bootleg.stop production      # Stops a deployed release.
mix bootleg.ping production      # Check status of running nodes
```

## Invoking a Bootleg task

There's also a way to invoke Bootleg tasks from Mix. Similar to the built-in Mix tasks above, here you can also target a specific deploy environment.

### Sample Bootleg task definitions

`config/deploy.exs`:

```elixir
use Bootleg.DSL
task :zap do
  IO.puts "do the zap thing"
end
```

`config/deploy/qa.exs`:

```elixir
use Bootleg.DSL
task :zap do
  IO.puts "no zappy"
end
```

### Invoking the Bootleg tasks

```console
# target the default deploy environment
mix bootleg.invoke zap
> "do the zap thing"
# target the "qa" deploy environment
mix bootleg.invoke qa zap
> "no zappy"
```

## Other Commands

```console
# Initializes a project for use with Bootleg
mix bootleg.init
```
