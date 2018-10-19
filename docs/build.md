# Build Strategies

Bootleg aims to cover the most common build strategies. Because the architecture on which your code runs must be the same as that with which your application was compiled, it's important to build your app in the right environment.

## Supported Build Strategies

### Local Machine

To build your app on the same machine where you're running Bootleg, just set the `build_type` config option:

```elixir
# config/deploy.exs
use Bootleg.DSL

config(:build_type, :local)
```

### Docker Container

To build your app within a Docker container, create a Dockerfile that reproduces the server environment you are targeting.

#### Create a Dockerfile

Create a file named `Dockerfile` in your project directory.

The example here is borrowed from Distillery's [excellent guide](https://hexdocs.pm/distillery/guides/building_in_docker.html):

```
FROM ubuntu:16.04

ENV REFRESHED_AT=2018-08-16 \
    LANG=en_US.UTF-8 \
    HOME=/opt/build \
    TERM=xterm

WORKDIR /opt/build

RUN \
  apt-get update -y && \
  apt-get install -y git wget vim locales && \
  locale-gen en_US.UTF-8 && \
  wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
  dpkg -i erlang-solutions_1.0_all.deb && \
  rm erlang-solutions_1.0_all.deb && \
  apt-get update -y && \
  apt-get install -y erlang elixir

CMD ["/bin/bash"]
```

#### Build Docker Image

A one-time build command is needed to set up your Docker image:

```sh
$ docker build -t elixir-ubuntu:latest .
```

#### Use Docker with Bootleg

To tell Bootleg to use Docker, set the `build_type` and specify the image name in the `build_image` option:

```elixir
# config/deploy.exs
use Bootleg.DSL

config(:build_type, :docker)
config(:build_image, elixir-ubuntu:latest")
```

### Remote Build Server

In order to build your project remotely, Bootleg requires that your build server be set up to compile Elixir code. Make sure you have already installed Elixir and Erlang on any build server you define.

To build your app on a remote build server, first define a `build` role:

```elixir
# config/deploy.exs
use Bootleg.DSL

role :build, "build.example.com", user: "develop", workspace: "/some/build/workspace"
```

When defining a role, host options such as public key can also be supplied. See [Roles and Host Options](roles.md) for more information.

## Build your app

To initiate the Build step, run the provided Mix task:

```sh
$ mix bootleg.build
```

If your application doesn't build at this point, the errors should point you towards the problem. But don't worry too much about it for right now. We'll cover additional configuration in the following pages.

