# Bootleg

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bootleg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:bootleg, "~> 0.1.0"}]
end
```

## Available Strategies

### Build

##### Remote SSH 

`Bootleg.Strategies.Build.RemoteSSH`

Options:

* `revision`
* `host`
* `user`
* `identity`
* `workspace`

### Deploy

##### Remote SSH

`Bootleg.Strategies.Deploy.RemoteSSH`

Options:

* `host`
* `user`
* `identity`
* `workspace`

### Archive

#### Local Directory
	
`Bootleg.Strategies.Archive.LocalDirectory`
	
Options:
	
* `archive_directory`: Path to folder where build archives will be stored.
* `max_archives`: How many builds to keep before pruning.

## Versioning

Bootleg uses the application version as defined in `mix.exs`. Whether your application version is set here or comes from another source (e.g. [a VERSION file](https://gist.github.com/jeffweiss/9df547a4e472e3cf5bd3)), Bootleg requires it to be a parseable [Elixir.Version](https://hexdocs.pm/elixir/Version.html).

## Configuration

Configure Bootleg in your app's `config.exs`:

```elixir
config :bootleg, app: "foo"
config :bootleg, build:
  [
    strategy: Bootleg.Strategies.Build.RemoteSSH,
    revision: "master",
    host: "your.build.server",
    user: "jsmith",
    identity: "/Users/jsmith/.ssh/foo-build.pem",
    workspace: "/tmp/foo/build",
  ]
config :bootleg, deploy:
  [
    strategy: Bootleg.Strategies.Deploy.RemoteSSH,
    host: "your.application.server",
    user: "ubuntu",
    identity: "/Users/jsmith/.ssh/foo-deploy-ecs.pem",
    workspace: "/home/web/foo/bootleg",
  ]
config :bootleg, archive:
  [
    strategy: Bootleg.Strategies.Archive.LocalDirectory,
    archive_directory: "/Users/jsmith/Documents/foo-releases/",
    max_archives: 3
  ]
```
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bootleg](https://hexdocs.pm/bootleg).

