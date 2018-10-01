# Bootleg

## About
Bootleg provides simple deployment and server automation for Elixir.

**Bootleg** is a simple set of commands that attempt to simplify building and deploying Elixir applications. The goal of the project is to provide an extensible framework that can support many different deployment scenarios with one common set of commands.

Out of the box, Bootleg provides remote build and remote server automation for your [Distillery](https://github.com/bitwalker/distillery) releases. Bootleg assumes your project is committed into a **git** repository and some of the build steps use this assumption
to handle code within the build process. If you are using another source control management (SCM) tool please consider contributing to Bootleg to
add additional support.

## Installation

```
def deps do
  [{:distillery, "~> 2.0", runtime: false},
   {:bootleg, "~> 0.8", runtime: false}]
end
```

## Build server setup

In order to build your project, Bootleg requires that your build server be set up to compile
Elixir code. Make sure you have already installed Elixir on any build server you define.

## Quick Start

### Initialize your project

This step is optional but if run will create an example `config/deploy.exs` file that you
can use as a starting point.

```sh
$ mix bootleg.init
```

### Configure your release parameters

```elixir
# config/deploy.exs
use Bootleg.DSL

role :build, "your-build-server.local", user: "develop", identity: "~/.ssh/id_deploy_rsa", workspace: "/some/build/workspace"
role :app, ["web1", "web2", "web3"], user: "admin", identity: "~/.ssh/id_deploy_rsa", workspace: "/var/myapp"
```

### build and deploy

```sh
$ mix bootleg.build
$ mix bootleg.deploy
$ mix bootleg.start
```

See also: [Phoenix support](https://hexdocs.pm/bootleg/phoenix.html)