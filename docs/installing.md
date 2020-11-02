# Installation

## Download Bootleg

Add to your `mix.exs` dependencies:

```elixir
def deps do
  [{:distillery, "~> 2.1.0", runtime: false},
   {:bootleg, "~> 0.13.0", runtime: false}]
end
```

Install Bootleg:

```bash
$ mix deps.get
```

## Set-up Distillery

!!! tip
    If upgrading from an earlier version of Distillery, you may want to generate a new `rel/config.exs` with which to compare your existing configuration.

If you do not have a `rel/config.exs` file, please follow the [Distillery guide](https://hexdocs.pm/distillery/introduction/installation.html) to create one. Generally this consists of running `mix distillery.init` and reviewing the resulting file.

## Set-up Bootleg

Bootleg will read configuration from the `config/deploy.exs` file.

A mix task is provided to bootstrap this file for you:

```bash
$ mix bootleg.init
```

Please open and review the created files. The next page will cover configuring Bootleg for your use.
