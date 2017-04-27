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

| Stage     | Strategy        | Module                                     |
|-----------|-----------------|--------------------------------------------|
| Build     | Remote GIT/SSH  | [Bootleg.Strategies.Build.RemoteSSH](lib/strategies/build/remote_ssh.ex)         |
| Deploy    | Remote GIT/SSH  | [Bootleg.Strategies.Deploy.RemoteSSH](lib/strategies/deploy/remote_ssh.ex)        |
| Archive   | Local Directory | [Bootleg.Strategies.Archive.LocalDirectory](lib/strategies/archive/local_directory.ex)  |
| Admin     | Remote GIT/SSH  | [Bootleg.Strategies.Administration.RemoteSSH](lib/strategies/administration/remote_ssh.ex)|


## Versioning

Bootleg uses the application version as defined in `mix.exs`. Whether your application version is set here or comes from another source (e.g. [a VERSION file](https://gist.github.com/jeffweiss/9df547a4e472e3cf5bd3)), Bootleg requires it to be a parseable [Elixir.Version](https://hexdocs.pm/elixir/Version.html).

## Configuration

Configure Bootleg in your app's `config.exs`:

```elixir
config :bootleg, app: "foo"
config :bootleg, build: [
	strategy: Bootleg.Strategies.Build.RemoteSSH,
	host: "build1.example.com",
	user: "jane",
	workspace: "/usr/local/my_app/build"
]
config :bootleg, deploy: [
	strategy: Bootleg.Strategies.Deploy.RemoteSSH,
	host: "build1.example.com",
	user: "jane",
	workspace: "/usr/local/my_app/release"
]
config :bootleg, administration: [
	strategy: Bootleg.Strategies.Administration.RemoteSSH,
	host: "build1.example.com",
	user: "jane",
	workspace: "/usr/local/my_app/release"
]
config :bootleg, archive: [
	strategy: Bootleg.Strategies.Archive.LocalDirectory,
	archive_directory: "/var/local/my_app/releases",
	max_archives: 5
]
```
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bootleg](https://hexdocs.pm/bootleg).

