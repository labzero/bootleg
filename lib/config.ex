defmodule Bootleg.Config do
  @moduledoc """
  Configuration for bootleg in general.

  The configuration is defined as a `Map` in the `Mix.Config` of the target project,
  under the key `:bootleg`. Attributes in the struct have a 1:1 relationship with
  the keys in the `Mix.Config`.

  ## Fields
  * `app` - The name of the app being managed by `Bootleg`.
  * `version` - The version of the app. Defaults to the `Mix.Project` version.
  * `build` - Configuration for the build tasks. This should be a `Map` in `Mix.Config`, and will
      be converted to a `Bootleg.BuildConfig` using `Bootleg.BuildConfig.init/1`.
  * `deploy` - Configuration for the deployment tasks. This should be a `Map` in `Mix.Config`, and will
      be converted to a `Bootleg.DeployConfig` using `Bootleg.DeployConfig.init/1`.

  ## Example

    ```
    config :bootlet, app: "my_app"
    config :bootleg, build: [
      strategy: Bootleg.Strategies.Build.RemoteSSH,
      host: "build1.example.com",
      user: "jane",
      workspace: "/usr/local/my_app/build"
    ]
    config :bootleg, deploy: [
      strategy: Bootleg.Strategies.Deploy.RemoteSSH,
      host: "deploy1.example.com",
      user: "jane",
      workspace: "/usr/local/my_app/release"
    ]
    config :bootleg, manage: [
      strategy: Bootleg.Strategies.Manage.RemoteSSH,
      host: "deploy1.example.com",
      user: "jane",
      workspace: "/usr/local/my_app/release"
    ]
    ```
  """

  alias Mix.Project
  alias Bootleg.Config.{DeployConfig, BuildConfig, ManageConfig, ArchiveConfig}

  @doc false
  @enforce_keys [:app, :version]
  defstruct [:app, :version, :build, :deploy, :archive, :manage]

  @doc """
  Creates a `Bootleg.Config` from the `Application` configuration (under the key `:bootleg`).

  The keys in the map should match the fields in the struct.
  """
  @type strategy :: {:strategy, [...]}
  @spec init([strategy]) :: %Bootleg.Config{}
  def init(options \\ []) do
    %__MODULE__{
      app: Project.config[:app],
      version: Project.config[:version],
      build: BuildConfig.init(default_option(options, :build)),
      deploy: DeployConfig.init(default_option(options, :deploy)),
      manage: ManageConfig.init(default_option(options, :manage)),
      archive: ArchiveConfig.init(default_option(options, :archive))
    }
  end

  defp default_option(config, key) do
    Keyword.get(config, key, get_config(key))
  end

  def get_config(key, default \\ nil) do
    Application.get_env(:bootleg, key, default)
  end
end
