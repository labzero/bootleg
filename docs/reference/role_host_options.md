# Role and Host Options Reference

## Role and host options

Options are set on roles and on hosts based on the order in which the roles are defined. You can define your own, but note that the following are used internally by Bootleg:

| Option | Description | Default |
|:---|:---|:---|
| `workspace` | Path of the remote build workspace (`:build` role) or application workspace (`:app` role) | `.` |
| `user` | SSH username | `#!elixir System.get_env("USER")` |
| `password` | SSH password | `#!elixir nil` |
| `identity` | SSH private key file path | `#!elixir nil` |
| `port` | SSH port | `22` |
| `env` | Map of environment variables and values with which to run commands on remote servers.<br>E.g. `#!elixir %{PORT: "1234", FOO: "bar"}`| `#!elixir %{}` |
| `replace_os_vars` | Controls the `REPLACE_OS_VARS` environment variable used by Distillery for release configuration | `#!elixir true` |
| `release_workspace` | This option can be used when the build server is also the application server.<br>For `:build` roles, this is the path where the newly-built release should be copied.<br>For `:app` roles, this is the path where the release should be found. You probably want to use the same value for both! | `#!elixir nil`         |

## Pass-through SSH options

In addition to the SSH options above, specifying other common `:ssh.connect` options will cause them to be used only when establishing SSH connections and they will not be saved as role or host options.[^1]

[^1]: The `user` host option is always available due to its use in remote build, Git push operations.

!!! info
    Refer to `Bootleg.SSH.supported_options/0` for the complete list of supported options, and [:ssh.connect](http://erlang.org/doc/man/ssh.html#type-client_options) for more information.
