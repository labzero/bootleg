Bootleg comes with several macros.

## Config

Within your Bootleg config files, `config/1` and `config/2` can be used to get and set arbitrary key value pairs.

In addition to the [built-in config options](/reference/options.md), you can set your own as needed:


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

## Remote

This is the workhorse of the Bootleg DSL. It executes shell commands on remote servers and returns the results. It takes a role and a block of commands to execute. The commands are executed on all servers belonging to the role, and raises an `SSHError` if an error is encountered. Optionally, a list of options can be provided to filter the hosts where the commands are run.

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
