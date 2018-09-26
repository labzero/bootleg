# Custom Workflows

## Bootleg Tasks

Bootleg defines a number of tasks that are used during the default workflow.

### Build Tasks
* `build` - build process for creating a release package
  * `init` - sets up a bare repository for pushing code to
  * `clean` - cleans the remote workspace
  * `push_remote` - pushes code to build server
  * `reset_remote` - checks out the branch specified by `refspec` option (defaults to `master`)
  * `compile` - compilation of your project
  * `generate_release` - generation of the release package
  * `download_release` - pulls down the release archive

### Deployment Tasks
* `deploy` - deploy of a release package
  * `upload_release`
  * `unpack_release`

### Build and Deploy
* `update`
  * `build`
  * `deploy`
  * `stop_silent`
  * `start`

### Management tasks
* `start` - starting of a release
* `stop` - stopping of a release
* `restart` - restarting of a release
* `ping` - check connectivity to a deployed app

## Hooks

Hooks may be defined by the user in order to perform additional (or exceptional)
operations before or after certain actions performed by Bootleg.

Hooks can be defined for any task (built-in or user defined), even those that do not exist. This can be used
to create an "event" that you want to respond to, but has no real "implementation".

To register a hook, use:

 * `before_task <:task> do ... end` - Before `task` executes, execute the provided code block.
 * `after_task <:task> do ... end` - After `task` executes, execute the provided code block.

For example:

```elixir
use Bootleg.DSL

before_task :build do
  IO.puts "Starting build..."
end

after_task :deploy do
  MyAPM.notify_deploy()
end
```

You can define multiple hooks for a task, and they will be executed in the order they are defined. For example:

```elixir
use Bootleg.DSL

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

There are a few ways for custom code to be executed during the Bootleg life
cycle. Before showing some examples, here's a quick glossary of the related
pieces.

 * `task <:identifier> do ... end` - Assign a block of code to the atom provided as `:identifier`.
   This can then be executed by using the `invoke` macro.
 * `invoke <:identifier>` - Execute the `task` code blocked identified by `:identifier`, as well as
   any before/after hooks.

**NOTE:** Invoking an undefined task is not an error and any registered hooks will still be executed.

```elixir
use Bootleg.DSL

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

The workhorse of the Bootleg DSL is `remote`: it executes shell commands on remote servers and returns
the results. It takes a role and a block of commands to execute. The commands are executed on all servers
belonging to the role, and raises an `SSHError` if an error is encountered. Optionally, a list of options
can be provided to filter the hosts where the commands are run.

```elixir
use Bootleg.DSL

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

# filtering - only runs on app hosts with an option of primary set to true
remote :app, filter: [primary: true] do
  "mix ecto.migrate"
end

# change working directory - creates a file `/tmp/foo`, regardless of the role
# workspace configuration
remote :app, cd: "/tmp" do
  "touch ./foo"
end
```


## Custom configuration and hooks

Similar to how `bootleg_phoenix` is implemented, you can make use of the hooks system to run some commands on the build server around compile time.

```elixir
task :phx_digest do
  remote :build, cd: "assets" do
    "npm install"
    "./node_modules/brunch/bin/brunch b -p"
  end
  remote :build do
    "MIX_ENV=prod mix phx.digest"
  end
end

after_task :compile, :phx_digest
```

## Task Providers

Sharing is a good thing. Bootleg supports loading
tasks from packages in a manner very similar to `Mix.Task`.

You can create and share custom tasks by namespacing a module under `Bootleg.Tasks` and passing a block of Bootleg DSL:

```elixir
defmodule Bootleg.Tasks.Foo do
  use Bootleg.Task do
    task :foo do
      IO.puts "Foo!!"
    end

    before_task :build, :foo
  end
end
```
In order to be found and loaded by Bootleg, external tasks need to be loaded via a `Mix.Project` dependency.

See also: [Bootleg.Task](https://hexdocs.pm/bootleg/Bootleg.Task.html#content) for additional examples.