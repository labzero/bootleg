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

## Configuring

Configure Bootleg in your app's `config.exs`:

```elixir
config :bootleg, app: "foo"
config :bootleg, build:
  [
    # common / required
    strategy: Bootleg.Strategies.Build.RemoteSSH,

    # build strategy-specific options
    revision: "master",
    host: "your.build.server.lan",
    user: "jsmith",
    identity: "/Users/jsmith/.ssh/id_rsa",
    workspace: "/tmp/foo/build",
  ]
config :bootleg, archive:
  [
    # common / required
    strategy: Bootleg.Strategies.Archive.LocalDirectory,

    # build strategy-specific options
    archive_directory: "/Users/jsmith/Documents/foo-releases/",
    max_archives: 3
  ]
```
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bootleg](https://hexdocs.pm/bootleg).

