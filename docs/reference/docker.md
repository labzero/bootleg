# Docker options

The below options are relevant to working with Docker images:

## Options

- `docker_build_image`
- `docker_build_opts`
- `docker_build_mount`

## Troubleshooting

### Build with local dependencies

If your application has references to unpublished or local dependencies, you may need to set extra configuration options.

#### Example

If a project `acme` is set up as a pango application and is set to load `acme-writer` via:

```elixir
# mix.exs
def deps do
  [{:acme_writer, path: "../acme-writer"}]
end
```

And the folder structure is:

```
- /home/frank/proj/acme-writer
- /home/frank/proj/acme
- /home/frank/proj/acme/config/deploy.exs
```

And the Dockerfile sets a `WORKDIR` of:

```
/opt/build
```

Then the `ex_path` should be set to the base folder (`proj`) and a custom workdir should be passed to the Docker `run` command:

```elixir
use Bootleg.DSL

config(:build_type, :docker)
config(:docker_build_image, "elixir-ubuntu:latest")
config(:docker_build_mount, "/home/frank/proj:/opt/build")
config(:docker_build_opts, ["-w", "/opt/build/acme"])
```

Now `/home/frank/proj` will be mounted as `/opt/build`, but the release will be built from within `/opt/build/acme`, and dependencies can be satisfied.

