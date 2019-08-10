## `Bootleg.UI`

There are several [built-in helpers](https://hexdocs.pm/bootleg/Bootleg.UI.html) to Bootleg that may be useful.

!!! example "config/deploy.exs"
    ```elixir
    use Bootleg.DSL
    alias Bootleg.UI

    task :foobar do
      if UI.yes?("Are you sure") do
        UI.info("Here we go!")
        invoke :wizardry
      end
    end
    ```

In this case, a `mix bootleg.invoke foobar` will prompt the user before invoking another task.

