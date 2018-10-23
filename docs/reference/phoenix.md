
When deploying a Phoenix application you will typically want to build your assets after the compilation of your application but before packaging it into a Distillery release.


### Drop-in Phoenix support

You may use the [bootleg_phoenix](https://github.com/labzero/bootleg_phoenix) package to automatically compile Phoenix assets **when building on remote servers**.

!!! example "mix.exs"
    ```elixir hl_lines="4"
    def deps do
      [{:distillery, "~> 2.0", runtime: false},
       {:bootleg, "~> 0.8", runtime: false},
       {:bootleg_phoenix, "~> 0.2", runtime: false}]
    end
    ```

### Custom asset compilation

You can write a task to run after the `:compile` task, and compile the assets yourself.

Here we run a few extra commands after compiling the application, but before generating the release.

!!! example "Remote compiling Phoenix assets with Brunch"
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

??? example "Remote compiling Phoenix assets with Webpack"
    ```elixir
    task :phx_digest do
      remote :build, cd: "assets" do
        "npm install"
        # npm >= 5.2.0:
        "npx webpack -p"
        # otherwise:
        # "./node_modules/.bin/webpack --mode production"
      end
      remote :build do
        "MIX_ENV=prod mix phx.digest"
      end
    end

    after_task :compile, :phx_digest
    ```
