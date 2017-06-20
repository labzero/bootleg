defmodule Bootleg.Config.ManageConfig do
  @moduledoc """
  Configuration for the administrative tasks.

  ## Fields
    * `workspace` - Absolute path to the directory where the deploy can be found.
    * `strategy` - The bootleg strategy to use for manage. Defaults to `Bootleg.Strategies.Manage.Distillery`.
    * `user` - The username to use when connecting to the deployment host.
    * `hosts` - The hostname(s) or IP(s) of the deployment host(s).
    * `identity` - Absolute path to a private key used to authenticate with the deployment host. This should be in `PEM` format.
    * `migration_module` - The name of an Elixir module in your app where migration functionality is located.
    * `migration_function` - The name of a function/1 in the `migration_module` to call. If left blank, a default value
        of `migrate` will be used. The only argument will be `Bootleg.Config.app/0`.

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
      user: config[:user],
      migration_module: config[:migration_module],
      migration_function: config[:migration_function]
    }
  end
end
