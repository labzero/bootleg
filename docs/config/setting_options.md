Various Bootleg options can be set to help tailor the building and deploying of your application.

## Setting config options

Options can be set in the main configuration file or within an environment configuration file.

!!! example "config/deploy.exs"
    ```elixir
    use Bootleg.DSL
    config :build_type, :local
    ```

!!! tip
    The config macro is used here to set internally-used options, but you can also use it via `config/1` and `config/2` to read and set your own arbitrary key-value pairs. See the [built-in macros](/reference/macros.md) for more information.

## Overriding options from deployment environments

!!! example "config/deploy.exs"
    ```elixir
    use Bootleg.DSL
    config :build_type, :local
    ```

Setting the same option in an environment configuration file will override the existing value when running in that environment:

!!! example "config/deploy/production.exs"
    ```elixir hl_lines="2"
    use Bootleg.DSL
    config :build_type, :remote
    role :remote, "buildprod.example.com", workspace: "/opt/build"
    ```

For the full list of options you can set, see the [options reference](/reference/options.md) page.
