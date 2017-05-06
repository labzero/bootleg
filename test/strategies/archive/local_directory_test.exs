defmodule LocalDirectoryTest do
  use ExUnit.Case, async: true
  doctest Bootleg

  alias Bootleg.Strategies.Archive.LocalDirectory, as: Archiver

  setup do
    %{
      filename: "build.tar.gz",
      config:
        %Bootleg.Config{
          app: "bootleg",
          version: "1.0.0",
          archive:
            %Bootleg.ArchiveConfig{
              max_archives: 5,
              archive_directory: "releases",
            }
        },
      bad_config:
        %Bootleg.Config{
          app: "Funky Monkey",
          version: "1.0.0",
          archive:
            %Bootleg.ArchiveConfig{
              max_archives: 1,
              archive_directory: nil,
            }
          }
    }
  end

  test "init good", %{config: config, filename: filename} do
    assert {:ok, _} = Archiver.archive(config, filename)
  end

  test "init bad", %{bad_config: config, filename: filename} do
    assert_raise RuntimeError, ~r/This strategy requires "archive_directory" to be configured/, fn ->
      Archiver.archive(config, filename)
    end
  end

  test "valid_build_file" do
    # acceptable format is version number followed by archive extension
    assert Archiver.valid_build_file("0.0.1.tar.gz") == true
    assert Archiver.valid_build_file("1.0.0-alpha.tar.gz") == true
    assert Archiver.valid_build_file("1.0.0-rc0.tar.gz") == true

    # unexpected filename format
    assert Archiver.valid_build_file("1.0.0.tgz") == false
    assert Archiver.valid_build_file("0.0.1") == false

    # invalid versions
    assert Archiver.valid_build_file("1.0.tar.gz") == false
    assert Archiver.valid_build_file("1.0.a.tar.gz") == false
  end

  test "filter_sort_builds" do
    pretend_files = [
      "1.2.tar.gz",
      "1.0.0.tgz",
      "1.0.5.bz2",
      "0.0.1-rc1.tar.gz",
      "0.0.1.tar.gz",
      "0.0.1-alpha.tar.gz",
      "4.0.4",
      "1.1.0-rc0.tar.gz",
      "1.0.1.tar.gz",
      "1.0.0-10.tar.gz",
      "1.0.1+build0.tar.gz"
    ]

    assert Archiver.filter_sort_builds(pretend_files) == [
      "0.0.1-alpha.tar.gz",
      "0.0.1-rc1.tar.gz",
      "0.0.1.tar.gz",
      "1.0.0-10.tar.gz",
      "1.0.1+build0.tar.gz",
      "1.0.1.tar.gz",
      "1.1.0-rc0.tar.gz"
    ]
  end

  test "archive to invalid directory", %{config: config} do
    invalid_config = %Bootleg.ArchiveConfig{
      max_archives: 1,
      archive_directory: "404",
    }
    assert_raise RuntimeError, ~r/Archive directory.*couldn't be created/, fn ->
      Archiver.archive(%{config | archive: invalid_config}, "build.tar.gz")
    end
  end

  test "archive when build file doesnt exist", %{config: config} do
    assert_raise RuntimeError, ~r/file not found: 404.tar.gz/, fn ->
      Archiver.archive(config, "404.tar.gz")
    end
  end

  test "archive when folder full of releases", %{config: config} do
    strategy_config = %Bootleg.ArchiveConfig{
      max_archives: 1,
      archive_directory: "big_release_folder",
    }
    Archiver.archive(%{config | archive: strategy_config}, "build.tar.gz")
  end

  test "archive to read-only folder", %{config: config} do
    strategy_config = %Bootleg.ArchiveConfig{
      max_archives: 1,
      archive_directory: "read_only_folder",
    }
    assert_raise RuntimeError, ~r/Error storing build/, fn ->
      Archiver.archive(%{config | archive: strategy_config}, "build.tar.gz")
    end
  end

  test "archive", %{config: config} do
    Archiver.archive(config, "build.tar.gz")
  end
end
