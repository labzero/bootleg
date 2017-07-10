defmodule LocalDirectoryTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  doctest Bootleg

  alias Bootleg.Strategies.Archive.LocalDirectory, as: Archiver

  @archive_directory "test/fixtures/releases"
  @build_tarball "build.tar.gz"

  setup do
    use Bootleg.Config

    config :app, "bootleg"
    config :version, "1.0.0"

    File.cp("test/fixtures/#{@build_tarball}", @build_tarball)
    on_exit fn ->
      File.rm(@build_tarball)
      File.rm(Path.join(@archive_directory, "1.0.0.tar.gz"))
    end
    %{
      filename: @build_tarball,
      config:
        %Bootleg.Config{
          archive:
            %Bootleg.Config.ArchiveConfig{
              max_archives: 5,
              archive_directory: @archive_directory,
            }
        },
      bad_config:
        %Bootleg.Config{
          archive:
            %Bootleg.Config.ArchiveConfig{
              max_archives: 1,
              archive_directory: nil,
            }
          }
    }
  end

  test "init good", %{config: config, filename: filename} do
    capture_io(fn ->
      assert {:ok, _} = Archiver.archive(config, filename)
    end)
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

  @tag skip: "Migrate to functional test"
  test "archive to invalid directory", %{config: config} do
    invalid_config = %Bootleg.Config.ArchiveConfig{
      max_archives: 1,
      archive_directory: "404",
    }
    assert_raise RuntimeError, ~r/Archive directory.*couldn't be created/, fn ->
      Archiver.archive(%{config | archive: invalid_config}, "build.tar.gz")
    end
  end

  @tag note: "Migrate to functional test"
  test "archive when build file doesnt exist", %{config: config} do
    assert_raise RuntimeError, ~r/file not found: 404.tar.gz/, fn ->
      Archiver.archive(config, "404.tar.gz")
    end
  end

  @tag skip: "Migrate to functional test"
  test "archive when folder full of releases", %{config: config} do
    strategy_config = %Bootleg.Config.ArchiveConfig{
      max_archives: 1,
      archive_directory: "big_release_folder",
    }
    capture_io(fn ->
      assert {:ok, "1.0.0.tar.gz"}
             == Archiver.archive(%{config | archive: strategy_config}, "build.tar.gz")
    end)
  end

  @tag skip: "Migrate to functional test"
  test "archive to read-only folder", %{config: config} do
    strategy_config = %Bootleg.Config.ArchiveConfig{
      max_archives: 1,
      archive_directory: "read_only_folder",
    }
    assert_raise RuntimeError, "Error: Build file not found: build.tar.gz", fn ->
      capture_io(fn ->
        Archiver.archive(%{config | archive: strategy_config}, "build.tar.gz")
      end)
    end
  end

  test "archive", %{config: config} do
    capture_io(fn ->
      assert {:ok, "1.0.0.tar.gz"}
             == Archiver.archive(config, "build.tar.gz")
    end)
  end
end
