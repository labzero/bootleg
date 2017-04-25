defmodule Bootleg do

  @moduledoc """
  Documentation for Bootleg.
  """

  alias Mix.Project
  
  defmodule BuildConfig do

    defstruct [:identity, :host, :mix_env, :revision, :strategy, :user, :workspace]

    def init(config) do
      %__MODULE__{
        identity: config[:identity],
        strategy: config[:strategy] || Bootleg.Strategies.Build.RemoteSSH,
        revision: Application.get_env(:bootleg, :revision), # TODO read from args      
        user: config[:user],
        host: config[:host],
        workspace: config[:workspace],      
        revision: config[:revision],        
        mix_env: Application.get_env(:bootleg, :mix_env, "prod")      
      }      
    end
  end

  defmodule DeployConfig do

    defstruct [:workspace, :identity, :host, :strategy, :user]

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

    defstruct [:strategy, :archive_directory, :max_archives]

    def init(config) do
      %__MODULE__{
        strategy: config[:strategy] || Bootleg.Strategies.Archive.LocalDirectory,
        archive_directory: config[:archive_directory],
        max_archives: config[:max_archives]
      }
    end
  end

  defmodule Config do

    defstruct [:app, :version, :build, :deploy, :archive]

    def init do
      %__MODULE__{
        app: Application.get_env(:bootleg, :app),
        version: Project.config[:version],            
        build: Bootleg.BuildConfig.init(Application.get_env(:bootleg, :build)),
        deploy: Bootleg.DeployConfig.init(Application.get_env(:bootleg, :deploy)),
        archive: Bootleg.ArchiveConfig.init(Application.get_env(:bootleg, :archive)),
      }
    end
  end

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
        Enum.map(missing, fn(x) -> "\"#{x}\"" end)
        |> Enum.join(", ")
      {:error, "This strategy requires #{missing_quoted} to be configured"}
    else
      :ok
    end
  end
end