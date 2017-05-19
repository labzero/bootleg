# Bootleg

Simple deployment for Elixir, written in Elixir.

**bootleg** is a simple set of commands that attempt to simplify building and deploying elixir applications. The goal of the project is to provide an extensible framework that can support many different deploy scenarios with one common set of commands.

Out of the box, bootleg provides remote build and remote server automation for you existing distillery releases.

## Quick Start

The only modification needed in your application is the inclusion of both `bootleg` and `distillery` in your project dependencies.

```elixir
def deps do
  [{:distillery, "~> 1.3",
   {:bootleg, "~> 0.1.0"}]
end
```

Bootleg can use a variety of deployment strategies, the default is a standard distillery release. To configure a basic deploy in bootleg, just tell it where to build your release and where to deploy and manage your release.

```elixir
# config/bootleg/config.exs
config :bootleg, build: [
	host: "build1.example.com",
	user: "bootleg",
	workspace: "/tmp/build/my_app"
]
config :bootleg, deploy: [
	hosts: ["prod1.example.com","prod2.example.com"],
	user: "bootleg",
	workspace: "/var/web/my_app"
]
config :bootleg, manage: [
	hosts: ["prod1.example.com","prod2.example.com"],
	user: "bootleg",
	workspace: "/var/web/my_app"
]
```

Build and deploy your release

```console
mix bootleg.build production
mix bootleg.deploy production
mix bootleg.start production
```

Alternatively the above commands can be rolled into one with:

```console
mix bootleg.update
```

## Installation

```elixir
def deps do
  [{:distillery, "~> 1.3",
   {:bootleg, "~> 0.1.0"}]
end
```

## Configuration

Configure Bootleg in your app's `config.exs`:

```elixir
config :bootleg, app: "foo"
config :bootleg, build: [
	revision: "master",
	strategy: Bootleg.Strategies.Build.Distillery,
	host: "build1.example.com",
	user: "jane",
	workspace: "/usr/local/my_app/build"
]
config :bootleg, deploy: [
	strategy: Bootleg.Strategies.Deploy.Distillery,
	hosts: ["prod1.example.com","prod2.example.com"],
	user: "jane",
	workspace: "/usr/local/my_app/release"
]
config :bootleg, manage: [
	strategy: Bootleg.Strategies.Manage.Distillery,
	hosts: ["prod1.example.com","prod2.example.com"],
	user: "jane",
	workspace: "/usr/local/my_app/release"
]
config :bootleg, archive: [
	strategy: Bootleg.Strategies.Archive.LocalDirectory,
	archive_directory: "/var/local/my_app/releases",
	max_archives: 5
]
```

## Available Strategies

| Stage     | Strategy        | Module                                     |
|-----------|-----------------|--------------------------------------------|
| Build     | Distillery  | [Bootleg.Strategies.Build.Distillery](lib/strategies/build/distillery.ex)         |
| Deploy    | Distillery  | [Bootleg.Strategies.Deploy.RemoteSSH](lib/strategies/deploy/distillery.ex)        |
| Archive   | Local Directory | [Bootleg.Strategies.Archive.LocalDirectory](lib/strategies/archive/local_directory.ex)  |
| Manage     | Distillery  | [Bootleg.Strategies.Manage.Distillery](lib/strategies/administration/distillery.ex)|


## Versioning

Bootleg uses the application version as defined in `mix.exs`. Whether your application version is set here or comes from another source (e.g. [a VERSION file](https://gist.github.com/jeffweiss/9df547a4e472e3cf5bd3)), Bootleg requires it to be a parseable [Elixir.Version](https://hexdocs.pm/elixir/Version.html).

## Admin Commands

bootleg has a set of commands to check up on your running nodes:

```console
mix bootleg.restart production  # Restarts a deployed release.
mix bootleg.start production      # Starts a deployed release.
mix bootleg.stop production      # Stops a deployed release.
mix bootleg.ping production      # Check status of running nodes
```


## Help

If something goes wrong, retry with the `--verbose` option. 
For detailed information about the bootleg commands and their options, try `mix bootleg help <command>`.

## Examples

Build a release and deploy it to your production hosts:

```sh
mix bootleg.build
mix bootleg.deploy
mix bootleg.start
```

Or execute the above steps with a single command:

```sh
mix bootleg.update production
```

# run ecto migrations manually:

```sh
mix bootleg.migrate
```
-----

## Contributing

We welcome everyone to contribute to Bootleg and help us tackle existing issues!

Use the [issue tracker][issues] for bug reports or feature requests.
Open a [pull request][pulls] when you are ready to contribute.

If you are planning to contribute documentation, please check
[the best practices for writing documentation][writing-docs].


## LICENSE

Bootleg source code is released under the MIT License.
Check the [LICENSE](LICENSE) file for more information.

  [issues]: https://github.com/labzero/bootleg/issues
  [pulls]: https://github.com/labzero/bootleg/pulls
  [writing-docs]: http://elixir-lang.org/docs/stable/elixir/writing-documentation.html



