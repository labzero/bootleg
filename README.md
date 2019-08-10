# Bootleg

[![CircleCI](https://img.shields.io/circleci/project/github/labzero/bootleg/master.svg)](https://circleci.com/gh/labzero/bootleg) [![Hex.pm](https://img.shields.io/hexpm/v/bootleg.svg)](https://hex.pm/packages/bootleg) [![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)](https://github.com/labzero/bootleg/blob/master/LICENSE)

Simple deployment and server automation for Elixir.

 * [Documentation](https://hexdocs.pm/bootleg)
 * [Phoenix support](https://hexdocs.pm/bootleg/reference/phoenix.html)
 * [Contributing](https://github.com/labzero/bootleg/blob/master/CONTRIBUTING.md)

**Bootleg** is a simple set of commands that attempt to simplify building and deploying Elixir applications. The goal of the project is to provide an extensible framework that can support many different deployment scenarios with one common set of commands.

Out of the box, Bootleg provides remote build and remote server automation for your [Distillery](https://github.com/bitwalker/distillery) releases. Bootleg assumes your project is committed into a **git** repository and some of the build steps use this assumption
to handle code within the build process. If you are using another source control management (SCM) tool please consider contributing to Bootleg to
add additional support.

## Installation

Add Distillery and Bootleg as dependencies to `mix.exs`:

```
def deps do
  [{:distillery, "~> 2.1", runtime: false},
   {:bootleg, "~> 0.11", runtime: false}]
end
```

## Quick start

### Create release configuration

If you're new to Distillery, run the init command to generate a `rel/` folder and configuration:

```
mix distillery.init
```

### Create deploy configuration

Similarly, Bootleg configuration can be generated:

```
mix bootleg.init
```

### Configure the deploy configuration

First define a build server in `config/deploy.exs`:

```
use Bootleg.DSL

role :build, "build.example.com", 
  workspace: "/home/acme/build",
  user: "acme",
  identity: "~/.ssh/id_acme_rsa",
  silently_accept_hosts: true

```   

Next, define application server(s) in `config/deploy/production.exs`:

```
use Bootleg.DSL

role :app, ["app1.example.com", "app2.example.com"],
  workspace: "/opt/acme",
  user: "acme",
  identity: "~/.ssh/id_acme_rsa",
  silently_accept_hosts: true
```


### Build, deploy and start your application   
Now you can proceed to build, deploy and start your application:

```
mix bootleg.build
mix bootleg.deploy
mix bootleg.start
```
This example was for building on a remote build server and deploying to one or more remote application servers, but Bootleg supports several other [build](https://hexdocs.pm/bootleg/config/build.html) and [deployment strategies](https://hexdocs.pm/bootleg/config/deploy.html).

## Help

Bootleg has [online documentation available](https://hexdocs.pm/bootleg) available:

For detailed information about the Bootleg commands and their options, try `mix bootleg help <command>`.

We're usually around on Slack where you can find us on [elixir-lang's #bootleg channel](http://elixir-lang.slack.com/messages/bootleg/) if you have any questions.

-----

## Acknowledgments

Bootleg makes heavy use of the [bitcrowd/SSHKit.ex](https://github.com/bitcrowd/sshkit.ex)
library under the hood. We are very appreciative of the efforts of the bitcrowd team for both creating SSHKit.ex and being so attentive to our requests. We're also grateful for the opportunity to collaborate
on ideas for both projects!

## Contributing

We welcome all contributions to Bootleg, whether they're improving the documentation, implementing features, reporting issues or suggesting new features.

If you'd like to contribute documentation, please check
[the best practices for writing documentation][writing-docs].


## LICENSE

Bootleg source code is released under the MIT License.
Check the [LICENSE](LICENSE) file for more information.

  [issues]: https://github.com/labzero/bootleg/issues
  [pulls]: https://github.com/labzero/bootleg/pulls
  [writing-docs]: https://hexdocs.pm/elixir/master/writing-documentation.html
