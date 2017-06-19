defmodule Bootleg.Config do
  @doc false

  defmacro __using__(_) do
    quote do
      import Bootleg.Config, only: [role: 2, role: 3, config: 2, config: 0]
      {:ok, agent} = Bootleg.Config.Agent.start_link
      # var!(config_agent, Bootleg.Config) = agent
    end
  end

  defmacro role(name, hosts, options \\ []) do
    host_list = List.wrap(hosts)
    user = Keyword.get(options, :user, System.get_env("USER"))
    options = Keyword.delete(options, :user)
    quote do
      Bootleg.Config.Agent.merge(
        :roles,
        unquote(name),
        %Bootleg.Role{
          name: unquote(name), hosts: unquote(host_list), user: unquote(user),
          options: unquote(options)
        }
      )
    end
  end

  def get_role(name) do
    Keyword.get(Bootleg.Config.Agent.get(:roles), name)
  end

  defmacro config do
    quote do
      Bootleg.Config.Agent.get(:config)
    end
  end

  defmacro config(key, value) do
    quote do
      Bootleg.Config.Agent.merge(
        :config,
        unquote(key),
        unquote(value)
      )
    end
  end

  ##################
  ####  LEGACY  ####
  ##################
  @moduledoc """
  Configuration for bootleg in general.

  The configuration is defined as a `Map` in the `Mix.Config` of the target project,
  under the key `:bootleg`. Attributes in the struct have a 1:1 relationship with
  the keys in the `Mix.Config`.

  ## Fields
  * `deploy` - Configuration for the deployment tasks. This should be a `Map` in `Mix.Config`, and will
      be converted to a `Bootleg.DeployConfig` using `Bootleg.DeployConfig.init/1`.

  ## Example

    ```
    config :bootleg, manage: [
      strategy: Bootleg.Strategies.Manage.RemoteSSH,
      host: "deploy1.example.com",
      user: "jane",
      workspace: "/usr/local/my_app/release"
    ]
    ```
  """

  alias Bootleg.Config.{ManageConfig, ArchiveConfig}

  @doc false
  @enforce_keys []
  defstruct [:archive, :manage]

  @doc """
  Creates a `Bootleg.Config` from the `Application` configuration (under the key `:bootleg`).

  The keys in the map should match the fields in the struct.
  """
  @type strategy :: {:strategy, [...]}
  @spec init([strategy]) :: %Bootleg.Config{}
  def init(options \\ []) do
    %__MODULE__{
      manage: ManageConfig.init(default_option(options, :manage)),
      archive: ArchiveConfig.init(default_option(options, :archive))
    }
  end

  defp default_option(config, key) do
    Keyword.get(config, key, get_config(key))
  end

  def get_config(key, default \\ nil) do
    Keyword.get(Bootleg.Config.Agent.get(:config), key, default)
  end

  def strategy(%Bootleg.Config{} = config, type) do
    get_in(config, [Access.key!(type), Access.key!(:strategy)])
  end
end
