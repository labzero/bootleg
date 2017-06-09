defmodule Bootleg.Config.DeployConfig do
  @moduledoc """
  Configuration for the deploy tasks.

  ## Fields
    * `workspace` - Absolute path to the directory where the deploy should be placed on the deployment host. This directory
        will be created if its not already.
    * `strategy` - The bootleg strategy to use for deployments. Defaults to `Bootleg.Strategies.Deploy.RemoteSSH`.
    * `user` - The username to use when connecting to the deployment host.
    * `host` - The hostname or IP of the deployment host.
    * `identity` - Absolute path to a private key used to authenticate with the deployment host. This should be in `PEM` format.

  ## Example

    ```
    config :bootleg, deploy: [
      strategy: Bootleg.Strategies.Deploy.RemoteSSH,
      hosts: ["deploy1.example.com","deploy2.example.com"]
      user: "jane",
      workspace: "/usr/local/my_app/release"
    ]
    ```
  """

  @doc false
  defstruct [:workspace, :identity, :hosts, :strategy, :user]

  @doc """
  Creates a `Bootleg.DeployConfig` struct.

  The keys in the `Map` should match the fields in the struct.
  """
  @spec init(map) :: %Bootleg.Config.DeployConfig{}
  def init(config) do
    %__MODULE__{
      workspace: config[:workspace],
      identity: config[:identity],
      hosts: config[:hosts],
      strategy: config[:strategy],
      user: config[:user]
    }
  end
end
