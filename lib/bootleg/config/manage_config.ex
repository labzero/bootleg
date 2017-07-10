defmodule Bootleg.Config.ManageConfig do
  @moduledoc """
  Configuration for the administrative tasks.

  ## Fields
    * `workspace` - Absolute path to the directory where the deploy can be found.
    * `strategy` - The bootleg strategy to use for manage. Defaults to `Bootleg.Strategies.Manage.Distillery`.
    * `user` - The username to use when connecting to the deployment host.
    * `hosts` - The hostname(s) or IP(s) of the deployment host(s).
    * `identity` - Absolute path to a private key used to authenticate with the deployment host. This should be in `PEM` format.

  ## Example

  """

  @doc false
  defstruct [:workspace, :identity, :hosts, :strategy, :user,
    :migration_module, :migration_function]

  @doc """
  Creates a `Bootleg.ManageConfig` struct.

  The keys in the `Map` should match the fields in the struct.
  """
  @spec init(map) :: %Bootleg.Config.ManageConfig{}
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
