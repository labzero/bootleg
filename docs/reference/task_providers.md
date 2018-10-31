
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
