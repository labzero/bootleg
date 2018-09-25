
# Roles

Actions in Bootleg are paired with roles, which are simply a collection of hosts that are responsible for the same function, for example building a release, archiving a release, or executing commands against a running application.

Role names are unique so there can only be one of each defined, but hosts can be grouped into one or more roles. Roles can be declared repeatedly to provide a different set of options to different sets of hosts.

By defining roles, you are defining responsibility groups to cross cut your host infrastructure. The `build` and
`app` roles have inherent meaning to the default behavior of Bootleg, but you may also define more that you can later filter on when running commands inside a Bootleg hook. There is another built in role `:all` which will always include
all hosts assigned to any role. `:all` is only available via `remote/2`.

Some features or extensions may require additional roles, for example if your
release needs to run Ecto migrations, you will need to assign the `:db`
role to one host.

### Local build option

You may not need a remote build server for all situations. In these cases, you can skip designating a `:build` role, and instead set the `:build_type` option to `"local"`. This will tell bootleg to skip all of the steps required to build the release on a remote server and instead built it locally.

```elixir
# deploy.exs
use Bootleg.DSL

config :build_type, "local"
```

## Role and host options

Options are set on roles and on hosts based on the order in which the roles are defined. Some are used internally
by Bootleg:

  * `workspace` - remote path specifying where to perform a build or push a deploy (default `.`)
  * `user` - ssh username (default to local user)
  * `password` - ssh password
  * `identity` - unencrypted private key file path (passphrases are not supported at this time)
  * `port` - ssh port (default `22`)
  * `env` - map of environment variable and values. ie: `%{PORT: "1234", FOO: "bar"}`
  * `replace_os_vars` - controls the `REPLACE_OS_VARS` environment variable used by Distillery for release configuration (default `true`)

`build` role specific option:
  * `release_workspace` - specify the remote path where the release is placed. If not specified the release is downloaded locally (default `nil`)

`app` role specific option:
  * `release_workspace` - specify the remote path where the release is copied from. If not specified the release is uploaded from local machine (defaul `nil`)

### Examples

```elixir
role :app, ["host1", "host2"], user: "deploy", identity: "/home/deploy/.ssh/deploy_key.priv"
role :app, ["host2"], port: 2222
```
> In this example, two hosts are declared for the `app` role, both as the user *deploy* but only *host2* will use the non-default port of *2222*.

```elixir
role :app, ["host1", "host2"], port: 2222, env: %{FOO: "bar", BIZ: "baz"}
```
> In this example, some additional environment variables are set for all `:app` hosts, `FOO=bar` and `BIZ=baz`.

```elixir
role :db, ["db.example.com", "db2.example.com"], user: "datadog"
role :db, "db.example.com", primary: true
```
> In this example, two hosts are declared for the `db` role but the first will receive a host-specific option for being the primary. Host options can be arbitrarily named and targeted by tasks.

```elixir
role :balancer, ["lb1.example.com", "lb2.example.com"], banana: "boat"
role :balancer, "lb3.example.com"
```
> In this example, two load balancers are configured with a host-specific option of *banana*. The `balancer` role itself also receives the role-specific option of *banana*. A third balancer is then configured without any specific host options.

```elixir
role :build, "example.com", workspace: "/home/deployer/builds", release_workspace: "/home/deployer"
role :app, "example.com", release_workspace: "/home/deployer"
```
> In this example, the release is built and deployed on the same remote. By specifying a `release_workspace` on the `:build` role, a release is placed in `home/deployer`. and by specifying a `release_workspace` on the `:app` role, the release is copied from the `/home/deployer` directory to the app workspace. Note that the release is not downloaded.
### SSH options

If you include any common `:ssh.connect` options they will not be included in role or host options and will only be used when establishing SSH connections (exception: *user* is always passed to role and hosts due to its relevance to source code management).

Supported SSH options include:

* user
* port
* timeout
* recv_timeout

> Refer to `Bootleg.SSH.supported_options/0` for the complete list of supported options, and [:ssh.connect](http://erlang.org/doc/man/ssh.html#connect-2) for more information.

## Role restrictions

Bootleg extensions may impose restrictions on certain roles, such as restricting them to a certain number of hosts. See the extension documentation for more information.

## Roles provided by Bootleg

* `build` - Takes only one host. If a list is given, only the first hosts is
used and a warning may result.
* `app` -  Takes a list of hosts, or a string with one host.
