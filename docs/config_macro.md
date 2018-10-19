# The Config Macro

The `config` macro can be used to get and set arbitrary key value pairs for use within Bootleg.

In addition to the [built-in config options](environments.md#internal-config-options), you can set your own as needed:


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
