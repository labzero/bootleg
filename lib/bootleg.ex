defmodule Bootleg do

  @moduledoc """
  Makes building and deploying your app easier then getting a prohibition-era drink.

  Integrating `Bootleg` into your application is a matter of setting up an appropriate configuration. See
  `Bootleg.Config` for details on configuration.
  """

  alias Mix.Project
  
  defmodule BuildConfig do
    @moduledoc """
    Configuration for the build tasks.

    The actual configuration values are set via the `Mix.Config` for
    the target project, as a `Map` under the `:bootleg` application.

    ## Fields
    * `strategy` - The bootleg strategy to use for builds. Defaults to `Bootleg.Strategies.Build.RemoteSSH`.
    * `workspace` - Absolute path to a directory on the build host where the build will occur. This directory
        will be created if its not already.
    * `revision` - The revision to build.
    * `user` - The username to use when connecting to the build host.
    * `host` - The hostname or IP of the build host.
    * `mix_env` - What `MIX_ENV` to use for the build.
    * `identity` - Absolute path to a private key used to authenticate with the build host. This should be in `PEM` format.

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
    defstruct [:identity, :host, :mix_env, :revision, :strategy, :user, :workspace]

    @doc """
    Creates a `Bootleg.BuildConfig`.

    The keys in the map should match the fields in the struct.
    """
    @spec init(map) :: %Bootleg.BuildConfig{}
    def init(config) do
      %__MODULE__{
        identity: config[:identity],
        strategy: config[:strategy] || Bootleg.Strategies.Build.RemoteSSH,
        revision: Application.get_env(:bootleg, :revision),
        user: config[:user],
        host: config[:host],
        workspace: config[:workspace],      
        revision: config[:revision],        
        mix_env: Application.get_env(:bootleg, :mix_env, "prod")      
      }      
    end
  end

  defmodule DeployConfig do
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
        host: "build1.example.com",
        user: "jane",
        workspace: "/usr/local/my_app/release"
      ]
      ```
    """

    @doc false
    defstruct [:workspace, :identity, :host, :strategy, :user]

    @doc """
    Creates a `Bootleg.DeployConfig` struct.

    The keys in the `Map` should match the fields in the struct.
    """
    @spec init(map) :: %Bootleg.DeployConfig{}
    def init(config) do
      %__MODULE__{
        workspace: config[:workspace],
        identity: config[:identity],
        host: config[:host],
        strategy: config[:strategy],
        user: config[:user]
      }      
    end

  end

  defmodule AdministrationConfig do
    @moduledoc """
    Configuration for the administrative tasks.

    ## Fields
      * `workspace` - Absolute path to the directory where the deploy can be found.
      * `strategy` - The bootleg strategy to use for administration. Defaults to `Bootleg.Strategies.Administration.RemoteSSH`.
      * `user` - The username to use when connecting to the deployment host.
      * `host` - The hostname or IP of the deployment host.
      * `identity` - Absolute path to a private key used to authenticate with the deployment host. This should be in `PEM` format.

    ## Example

      ```
      config :bootleg, administration: [
        strategy: Bootleg.Strategies.Administration.RemoteSSH,
        host: "build1.example.com",
        user: "jane",
        workspace: "/usr/local/my_app/release"
      ]
      ```
    """

    @doc false
    defstruct [:workspace, :identity, :host, :strategy, :user]

    @doc """
    Creates a `Bootleg.AdministrationConfig` struct.

    The keys in the `Map` should match the fields in the struct.
    """
    @spec init(map) :: %Bootleg.AdministrationConfig{}
    def init(config) do
      %__MODULE__{
        workspace: config[:workspace],
        identity: config[:identity],
        host: config[:host],
        strategy: config[:strategy],
        user: config[:user]
      }
    end
  end

  defmodule ArchiveConfig do

    @doc false
    defstruct [:strategy, :archive_directory, :max_archives]

    @doc """
    """
    def init(config) do
      %__MODULE__{
        strategy: config[:strategy] || Bootleg.Strategies.Archive.LocalDirectory,
        archive_directory: config[:archive_directory],
        max_archives: config[:max_archives]
      }
    end
  end

  defmodule Config do
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
    * `push_options` - Any extra options to use for `git push`, defaults to `-f` (force push).
    * `refspec` - Which git [refspec](https://git-scm.com/book/id/v2/Git-Internals-The-Refspec) to use when pushing, defaults to `master`.

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
      config :bootleg, administration: [
        strategy: Bootleg.Strategies.Administration.RemoteSSH,
        host: "deploy1.example.com",
        user: "jane",
        workspace: "/usr/local/my_app/release"
      ]
      ```
    """

    @doc false
    defstruct [:app, :version, :build, :deploy, :archive, :push_options, :refspec, :administration]

    @doc """
    Creates a `Bootleg.Config` from the `Application` configuration (under the key `:bootleg`).

    The keys in the map should match the fields in the struct.
    """
    @spec init :: %Bootleg.Config{build: %Bootleg.BuildConfig{}, deploy: %Bootleg.DeployConfig{}, archive: %Bootleg.ArchiveConfig{}}
    def init do
      %__MODULE__{
        app: Application.get_env(:bootleg, :app),
        version: Project.config[:version],            
        build: Bootleg.BuildConfig.init(Application.get_env(:bootleg, :build)),
        deploy: Bootleg.DeployConfig.init(Application.get_env(:bootleg, :deploy)),
        administration: Bootleg.AdministrationConfig.init(Application.get_env(:bootleg, :administration)),
        push_options: Application.get_env(:bootleg, :push_options),
        refspec: Application.get_env(:bootleg, :refspec),
        archive: Bootleg.ArchiveConfig.init(Application.get_env(:bootleg, :archive))
      }
    end
  end

  @doc "Alias for `Bootleg.Config.init/0`."
  @spec config :: %Bootleg.Config{}
  def config do
    Bootleg.Config.init()
  end

  @doc """
  Check for the presence and non-nil value of one or more terms in a config.
  Used by individual strategies to enforce required settings.
  """
  @spec check_config(struct(), [String.t]) :: :ok | {:error, String.t}
  def check_config(config, terms) do
    missing = Enum.filter(terms,
                          &(Map.get(config, String.to_atom(&1), nil) == nil))

    if Enum.count(missing) > 0 do
      missing_quoted =
        missing
        |> Enum.map(fn(x) -> "\"#{x}\"" end)
        |> Enum.join(", ")
      {:error, "This strategy requires #{missing_quoted} to be configured"}
    else
      :ok
    end
  end
end
