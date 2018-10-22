# Public key support

Bootleg supports the use of SSH identity files for passwordless connections.

## Private keys

In many cases, private keys are not protected by a passphrase and do not need to be unlocked before use.
This is ideal for tools like Bootleg which lack a user interface.

When defining your roles and hosts, simply add an `identity` option pointing to your private SSH key.

!!! example "Specifying an identity file"
    ```elixir
    use Bootleg.DSL

    role :app, "example.com", identity: "~/.ssh/id_rsa"
    ```

The SSH private key will be used in remote builds (Git push) and for remote execution of commands.

## Passphrase-protected private keys

Private keys that are protected by a passphrase need to be unlocked before use. By using the `passphrase` or `passphrase_provider` host options, the passphrase will be handed off to the `ssh_client_key_api` package, which will attempt to use it to unlock the key.

However, the remote build scenario normally uses a Git push, which as an external process **does not** work seamlessly
with the aforementioned Bootleg options. See "[Remote builds](#remote-builds)" below for solutions.

### Options for protected private keys

#### `passphrase`

When configuring your role, set the `passphrase` option to the string that unlocks your private key.

#### `passphrase_provider`

Instead of setting a `passphrase`, you may set `passphrase_provider` to something that returns the string to unlock your private key. When using a provider, the returned value is then set as the `passphrase` option at time of `SSH.init/3`.

##### Anonymous function

```elixir
role(:app, "example.com", identity: "protected_id_rsa", passphrase_provider: fn -> "foobar" end)
```

##### Module and function reference

```elixir
defmodule Test.Foo do
  def bar do
    "foobar"
  end
end
role(:app, "example.com", identity: "protected_id_rsa", passphrase_provider: {Test.Foo, :bar})
```

##### System command and arguments

```elixir
role(:app, "example.com", identity: "protected_id_rsa", passphrase_provider: {"/bin/echo", ["foobar"]})
```

### Local builds

When your build server is the same machine you're running Bootleg on, you may define the passphrase alongside the identity.

```elixir
role :app, "example.com", identity: "~/.ssh/protected_id_rsa", passphrase: "secretsauce"
```

### Remote builds

When your build server is another machine, the build process will attempt to do a Git push to it.
This requires that you unlock your private key in one of two ways:

#### Using the `insecure_agent` Bootleg role option (preferred)

To use this option, set a passphrase options above, but also set `insecure_agent` on the role.

During the build process, the passphrase will be temporarily written to the filesystem in order
to unlock the key using `ssh-add`. This file is then removed immediately after the Git push operation.

```elixir
role :build, "example.com", identity: "~/.ssh/protected_id_rsa", passphrase: "secretsauce", insecure_agent: true
```

#### Using `ssh-agent` (external to Bootleg)

With ssh-agent, the Git push command will succeed but a passphrase is still needed for Bootleg to use your private key during execution of remote commands.

```elixir
role :build, "example.com", identity: "~/.ssh/protected_id_rsa", passphrase: "secretsauce"
```

Here you would run `$ ssh-add ~/.ssh/protected_id_rsa` before invoking Bootleg to provide the passphrase that unlocks your private key. After specifying the correct passphrase your key is added to the SSH Agent and Git push operations will succeed as expected.

Then run Bootleg as you would.
