defmodule Bootleg.Config.BuildConfig do
  @moduledoc """
  Configuration for the build tasks.

  The actual configuration values are set via the `Mix.Config` for
  the target project, as a `Map` under the `:bootleg` application.

  ## Fields
  * `strategy` - The bootleg strategy to use for builds. Defaults to `Bootleg.Strategies.Build.RemoteSSH`.
  * `workspace` - Absolute path to a directory on the build host where the build will occur. This directory
      will be created if its not already.
  * `user` - The username to use when connecting to the build host.
  * `host` - The hostname or IP of the build host.
  * `mix_env` - What `MIX_ENV` to use for the build.
  * `identity` - Absolute path to a private key used to authenticate with the build host. This should be in `PEM` format.
  * `push_options` - Any extra options to use for `git push`, defaults to `-f` (force push).
  * `refspec` - Which git [refspec](https://git-scm.com/book/id/v2/Git-Internals-The-Refspec) to use when pushing, defaults to `master`.

  ## Example

    ```
    config :bootleg, build: [
      strategy: Bootleg.Strategies.Build.RemoteSSH,
      host: "build1.example.com",
      user: "jane",
      workspace: "/usr/local/my_app/build"
    ]
    ```
  """

  @doc false
  #@enforce_keys [:host, :strategy, :workspace, :refspec]
  defstruct [:identity, :host, :mix_env, :strategy, :user, :workspace, :push_options, :refspec]

  @doc """
  Creates a `Bootleg.BuildConfig`.

  The keys in the map should match the fields in the struct.
  """
  @spec init(map) :: %Bootleg.Config.BuildConfig{}
  def init(config) do
    %__MODULE__{
      identity: config[:identity],
      strategy: config[:strategy] || Bootleg.Strategies.Build.RemoteSSH,
      user: config[:user],
      host: config[:host],
      workspace: config[:workspace],
      mix_env: config[:mix_env] || "prod",
      refspec: config[:refspec],
      push_options: config[:push_options] || "-f"
    }
  end
end
