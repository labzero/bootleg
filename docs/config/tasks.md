## Defining tasks

Tasks are basically functions defined within Bootleg configuration files to accomplish one or more goals in the deployment process.

!!! example "Example - Clear an application cache"
    ```elixir
    use Bootleg.DSL

    task :clear_cache do
      UI.puts "Clearing cache"
      remote :app do
        "rm /opt/app/cachefile"
      end
    end
    ```
    Here we define a task that will run a command on all `:app` servers.

Existing tasks, including those that come with Bootleg, can be redefined by you as needed.

???+ example "Redefining a built-in task"
    ```elixir tab="Config"
    use Bootleg.DSL
    task :build do
      UI.info("Doing our own thing!")
    end
    ```

    ```bash tab="Output"
    $ mix bootleg.build
    Warning: task 'build' is being redefined. The most recent definition will be used.
    To prevent this warning, set `override: true` in the task options. The previous
    definition was at: path/to/bootleg/lib/bootleg/tasks/build.exs:13
    Doing our own thing!
    ```

In order to squelch the warning that a task is being overridden, you may supply `override: true` to the `task` macro:

???+ example "Redefining a built-in task without triggering a warning"
    ```elixir tab="Config"
    use Bootleg.DSL
    task :build, override: true do
      UI.info("Doing our own thing!")
    end
    ```

    ```bash tab="Output"
    $ mix bootleg.build
    Doing our own thing!
    ```


## Running tasks

### Invoking tasks from the command line

Bootleg comes with several Mix tasks, but the one we'll show you here is called **invoke**.

!!! example "Using bootleg.invoke"
    ```bash
    $ mix bootleg.invoke foo
    Clearing cache
    ...[snip]
    ```
    The result of the command having been run on the `:app` servers would appear here.

### Invoking tasks from other tasks

!!! example "Tasks can invoke other tasks."
    ```elixir tab="Config"
    use Bootleg.DSL

    task :one do
      invoke :two
    end

    task :two do
      UI.puts "tada!"
    end
    ```

    ```bash tab="Output"
    $ mix bootleg.invoke one
    tada!
    $ mix bootleg.invoke two
    tada!
    ```

Invoking a task will also invoke any tasks that have been registered to run as hooks before/after that task.

!!! note
    Invoking an undefined task is not an error and any registered hooks for that task will still be executed.

## Using hooks

In addition to being run from tasks, tasks can be set to run before or after other tasks.

### Defining hooks for arbitrary tasks

Hooks can be defined for any task (built-in or user defined), even those that do not exist. This can be used
to create an "event" that you want to respond to, but has no real "implementation".

!!! example "Future proofed"
    ```elixir
    use Bootleg.DSL

    before_task :the_big_one do
      IO.puts "it's time to get outta here!"
    end
    ```
    This is valid even though there is no task registered with the name `:the_big_one`.

### Hooking into built-in Bootleg tasks

Much of Bootleg is written using Bootleg tasks. This means you can hook into many different parts of the build and deployment process.

!!! example "Notifying an external service"
    ```elixir
    use Bootleg.DSL

    before_task :build do
      MyAPM.notify_build()
    end

    after_task :deploy do
      MyAPM.notify_deploy()
    end
    ```

For a list of tasks that you can hook into, refer to the [workflows](/reference/workflow.md).

### Defining multiple hooks for the same task

You can define multiple hooks for a task, and they will be executed in the order they are defined.

!!! example "Using multiple hooks"
    ```elixir tab="Config"
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

    ```bash tab="Output"
    $ mix bootleg.invoke start
    This may take a bit
    Starting app!
    Started app!
    ```

    When invoking a task, the order in which hooks have been defined for that task is respected.
