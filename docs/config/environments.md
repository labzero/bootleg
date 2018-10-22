# Environments

Bootleg has its own concept of environments, which is analogous to but different from `MIX_ENV`. Bootleg environments can be used if you have multiple clusters that you deploy your code to, such as a QA or staging cluster, in addition to
your production cluster.

## Configuration structure

If you bootstrapped your config as detailed in the [Installing](/installing.md#set-up-bootleg) section the following files should already exist:

    :::plain
    mix.exs
    ├── config/
        ├── deploy.exs           # Main Bootleg config
        └── deploy/
            └── production.exs   # Environment-specific detail

## Specifying a Bootleg environment

To invoke a [Bootleg Mix Task](/reference/mix.md) with a specific environment, simply pass the name of the environment as the first argument. That environment's config file will be loaded immediately after `config/deploy.exs`.

For example, say you have both a `production` and a `staging` cluster. Your configuration might look something like this:

    :::plain
    mix.exs
    ├── config/
        ├── deploy.exs
        └── deploy/
            ├── staging.exs
            └── production.exs

!!! example "Using the Staging Environment"
    ```sh
    $ mix bootleg.update staging
    Starting remote build for staging environment
    ```

!!! example "Using the Production Environment"
    ```sh
    $ mix bootleg.update production
    Starting remote build for production environment
    ```

The default environment is `production`, though this can be changed in your configuration.

!!! example "Using the default Environment"
    ```sh
    $ mix bootleg.update
    Starting remote build for production environment
    ```


