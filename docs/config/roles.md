
# Roles

Actions in Bootleg are paired with roles, which are simply a collection of hosts that are responsible for the same function, for example building a release, archiving a release, or executing commands against a running application.

Hosts can be grouped into one or more roles. Roles can be declared repeatedly to provide options to different sets of hosts.


## Roles provided by Bootleg

| Role | Description |
|:---|:---|
| `#!elixir :build` | Takes only one host. If a list is given, only the first host is used. |
| `#!elixir :app` | Takes a list of hosts, or a string with one host. |

## Defining your own roles

By defining roles, you are defining responsibility groups to cross cut your host infrastructure. The `build` and
`app` roles have inherent meaning to the default behavior of Bootleg, but you may also define more that you can later filter on when running commands inside a Bootleg hook. 

Certain functionality or extensions may require additional roles, for example if your
release needs to run Ecto migrations, you could assign a `#!elixir primary: true`
option to one host and then filter on it.

### Syntax

The `role` macro requires both a name, specified as an atom, and a host or list of hosts. Any options you want to apply to those hosts can also be supplied.

### Examples

!!! example "Setting a different SSH option on a single host"
    ```elixir
    role :app, ["host1", "host2"], user: "deploy", identity: "/home/deploy/.ssh/deploy_key.priv"
    role :app, "host2", port: 2222
    ```
    Two hosts are declared for the `app` role. Both will use a username of `deploy` and the same public key identity file. Only **host2** will use the non-standard port of *2222*.

!!! example "Setting environment variables for the remote commands"
    ```elixir
    role :app, ["host1", "host2"], env: %{FOO: "bar", BIZ: "baz"}
    ```
    Two hosts are declared for the `app` role, both using environment variables set for any commands run remotely, `FOO=bar` and `BIZ=baz`.

!!! example "Setting your own host options"
    ```elixir
    role :db, ["db.example.com", "db2.example.com"], user: "datadog"
    role :db, "db.example.com", primary: true
    ```
    Two hosts are declared for the `db` role. Only `db.example.com` will receive an additional host-specific option for being the primary. Host options can be arbitrarily named and targeted by tasks.

!!! example "Using an internal role option to change behavior"
    Some host options are defined in Bootleg and have special meaning. `release_workspace` can be used when a single remote server is used to both build and run the application.
    ```elixir
    role :build, "example.com", workspace: "/home/deployer/builds", release_workspace: "/home/deployer"
    role :app, "example.com", release_workspace: "/home/deployer"
    ```
    By specifying a `release_workspace` on the `:build` role, a release is placed in `/home/deployer` after it is built. By specifying a `release_workspace` on the `:app` role, that same release is copied from the `/home/deployer` directory to the app workspace.

### Additional behaviors

There is another built-in role `:all` which includes all hosts assigned to any role. `:all` is only available via `remote/2`.
