defmodule Bootleg.Strategies.Archive.LocalDirectory do
  @moduledoc ""

  alias Bootleg.Config
  alias Bootleg.ArchiveConfig

  @config_keys ~w(archive_directory max_archives)

  @file_date_fmt "%Y%m%d%H%M%S"
  @file_extension ".tar.gz"
  @file_regexp ~r/^\d{14}\.tar.gz$/

  def archive(%Config{archive: %ArchiveConfig{archive_directory: archive_directory, max_archives: max_archives} = config}, build_filename) do
    with :ok <- Bootleg.check_config(config, @config_keys),
         :ok <- check_directory(archive_directory),
         {:ok, datestamp} <- check_build(build_filename),
         :ok <- trim_builds(archive_directory, max_archives),
         {:ok, archive_filename} <- archive_build(archive_directory, build_filename, datestamp) do
      IO.puts "Archival complete: #{Path.relative_to_cwd(archive_filename)}"
    else
      {:error, msg} -> raise "Error: #{msg}"
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
    with {:ok, stat} <- File.stat(filename, time: :local),
         {:ok, datestamp} <- Calendar.Strftime.strftime(stat.mtime, @file_date_fmt) do
      {:ok, datestamp}
    else
      {:error, :enoent} -> {:error, "Build file not found: #{filename}"}
    end
  end

  defp trim_builds(directory, limit) do
    with {:ok, files} <- File.ls(directory),
         builds = filter_builds(files),
         sorted_builds = sort_builds(builds) do
      num_builds = Enum.count(sorted_builds)

      if num_builds > limit do
        IO.puts "Pruning old builds"
        delete_files(directory, Enum.take(sorted_builds, num_builds - limit))
      end
      
      :ok
    else
      {:error, _error} -> raise "Error: Can't read files to prune old builds"
    end
  end

  defp archive_build(directory, filename, datestamp) do
    new_path = Path.join([directory, "#{datestamp}#{@file_extension}"])

    with {:ok, _} <- File.copy(filename, new_path) do
      {:ok, new_path}
    else
      {:error, :eacces} -> {:error, "Access denied to file #{filename}"}
      {:error, _error} -> {:error, "Could not archive build to #{new_path}"}
    end
  end

  defp filter_builds(files) do
    Enum.filter(files, &valid_build_file/1)
  end

  defp valid_build_file(filename) do
    Regex.match?(@file_regexp, filename)
  end

  defp sort_builds(files) do
    Enum.sort(files)
  end

  defp delete_files(directory, old_files) do
    Enum.each(old_files, 
      fn(filename) -> File.rm(Path.join(directory, filename)) end)
  end
end
