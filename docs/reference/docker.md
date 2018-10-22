
## Build with local dependencies

If your application has references to unpublished or local dependencies, you may need to set extra configuration options.

#### Example

- If the `acme` application is set up as a [poncho project](https://embedded-elixir.com/post/2017-05-19-poncho-projects/) and is set to load `acme-writer` via:

!!! example "mix.exs"
    ```elixir
    # mix.exs
    def deps do
      [{:acme_writer, path: "../acme-writer"}]
    end
    ```

- And the folder structure is:

```
- /home/frank/proj/acme-writer
- /home/frank/proj/acme
- /home/frank/proj/acme/config/deploy.exs
```

- And the Dockerfile sets a `WORKDIR` of `/opt/build`,

Then we need to mount the `proj` folder as `/opt/build`, and use a custom working directory when running the build commands:

```elixir hl_lines="5 6"
use Bootleg.DSL

config(:build_type, :docker)
config(:docker_build_image, "elixir-ubuntu:latest")
config(:docker_build_mount, "/home/frank/proj:/opt/build")
config(:docker_build_opts, ["-w", "/opt/build/acme"])
```

Now `/home/frank/proj` will be mounted as `/opt/build`, but the release will be built from within `/opt/build/acme`, and dependencies can be satisfied.

