defmodule Bootleg.Config.ArchiveConfig do
  @moduledoc """
  Configuration for the archiving tasks.

  ## Fields
    * `archive_directory` - Path to folder where build archives will be stored
    * `max_archives` - How many builds to keep before pruning

  ## Example

    ```
    config :bootleg, archive: [
      strategy: Bootleg.Strategies.Archive.LocalDirectory,
      archive_directory: "/var/local/my_app/releases",
      max_archives: 5
    ]
    ```
  """

  @doc """
  Creates a `Bootleg.ArchiveConfig` struct.

  The keys in the `Map` should match the fields in the struct.
  """
  @spec init(map) :: %Bootleg.Config.ArchiveConfig{}
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
