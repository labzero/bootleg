# Usage

## Distillery

### Runtime Configuration

From the [Distillery docs](https://hexdocs.pm/distillery/runtime-configuration.html#content):

> With Mix projects, your configuration is evaluated at runtime, so you can use functions such as System.get_env/1 to conditionally change configuration based on the runtime environment. **With releases, config.exs is evaluated at build time, and converted to a sys.config file. Using functions like System.get_env/1 will result in incorrect configuration.**

This means if you are using a 12FA-style environment variable configuration for your app, your build systems would potentially need to be configured with those same variables.

One solution is to set `REPLACE_OS_VARS=true` in your build environment and define shell-style variables in configuration strings that Distillery's runtime will automagically replace when first running the build on the target deployment.

  config :sauce, api_url: "${SAUCE_API_URL}"

Another solution is to use [Confex]() or a [configuration wrapper](https://gist.github.com/bitwalker/a4f73b33aea43951fe19b242d06da7b9) that knows how to understand and read configuration values such as `{:system, "VAR"}` from the environment at runtime. However, you may still be at the mercy of your application's dependencies.

Yet another solution is to use [Conform](https://github.com/bitwalker/conform), by the same author as Distillery, which addresses the core issue and provides additional benefits like validation of end-user configuration against a schema and an easy-to-use configuration file for end-users and/or system administrators.








