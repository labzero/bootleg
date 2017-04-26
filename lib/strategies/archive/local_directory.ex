defmodule Bootleg.Strategies.Archive.LocalDirectory do
  @moduledoc """
  Archive strategy for storing builds on the local filesystem

  Configurable options include:
  - path to build archive folder
  - maximum number of archives to store (and automatically prune)

  Archives are named using the release version number, which by design must
  be parseable as an Elixir.Version. Archives are sorted by version with the
  oldest versions being those that are pruned first.
  """

  alias Bootleg.Config
  alias Bootleg.ArchiveConfig

  @file_extension ".tar.gz"
  @config_keys ~w(archive_directory max_archives)

  @doc """
  Archive the build filename passed to us
  """
  def archive(%Config{version: version, archive: %ArchiveConfig{archive_directory: directory, max_archives: max_archives} = config}, build_filename) do
    with :ok <- Bootleg.check_config(config, @config_keys),
         :ok <- check_directory(directory),
         :ok <- check_build(build_filename),
         {:ok, archive_path} <- copy_build(directory, build_filename, version),
         {:ok, builds} <- trim_builds(directory, max_archives) do

      archive_filename = Path.basename(archive_path)
      Enum.each(builds, fn(filename) ->
        out = case archive_filename == filename do
          true -> "--> "
          false -> "... "
        end
        IO.puts out <> String.trim_trailing(filename, @file_extension)
      end)

      IO.puts "Archival complete: #{archive_path}"
      {:ok, archive_filename}
    else
      {:error, msg} -> raise "Error: #{msg}"
    end
  end

  @doc """
  Given a list of files, filter out any that are improperly named, and then
  sort them in order of version ascending.
  """
  def filter_sort_builds(files) do
    files
    |> Enum.filter(&valid_build_file/1)
    |> Enum.map(&String.trim_trailing(&1, @file_extension))
    |> Enum.sort(&sort_version/2)
    |> Enum.map(&(&1 <> @file_extension))
    |> Enum.reverse()
  end

  @doc """
  Check whether an archive is named appropriately to be considered a prior
  build, including whether its version number is legitimate.
  In the case of an invalid version exception, `false` is returned.
  """
  def valid_build_file(filename) do
    case String.ends_with?(filename, @file_extension) do
      true ->
        case Version.parse(String.trim_trailing(filename, @file_extension)) do
          {:ok, _} -> true
          :error -> false
        end
      false -> false
    end
  rescue
    Version.InvalidVersionError -> false
  end

  defp sort_version(a, b) do
    case Version.compare(a, b) do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  end

  defp check_directory(directory) do
    with {:ok, %File.Stat{type: :directory}} <- File.stat(directory) do
      :ok
    else
      {:error, :enoent} -> {:error, "Archive directory doesn't exist: #{directory}"}
    end
  end

  defp check_build(filename) do
    case File.exists?(filename) do
      true -> IO.puts "Build located at #{filename}"
              :ok
      false -> {:error, "Build file not found: #{filename}"}
    end
  end

  defp trim_builds(directory, limit) do
    with {:ok, files} <- File.ls(directory),
         builds = filter_sort_builds(files) do
      num_builds = Enum.count(builds)

      if num_builds > limit do
        IO.puts "Pruning old builds"
        old = Enum.take(builds, num_builds - limit)
        delete_files(directory, old)
        {:ok, builds -- old}
      else
        {:ok, builds}
      end
    else
      {:error, error} -> raise "Error: #{error}"
    end
  end

  defp copy_build(directory, filename, version) do
    new_path = Path.join([directory, "#{version}#{@file_extension}"])
    IO.puts "Storing build as #{version}#{@file_extension}"
    with {:ok, _} <- File.copy(filename, new_path) do
      {:ok, new_path}
    else
      {:error, :eacces} -> {:error, "Access denied to file #{filename}"}
      {:error, error} -> {:error, "Error: #{error}"}
    end
  end

  defp delete_files(directory, old_files) do
    Enum.each(old_files, fn(filename) ->
      IO.puts("-x- " <> String.trim_trailing(filename, @file_extension))
      File.rm(Path.join(directory, filename))
    end)
  end
end
