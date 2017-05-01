defmodule LocalDirectoryTest do
  use ExUnit.Case, async: true
  doctest Bootleg

  import Bootleg.Strategies.Archive.LocalDirectory, 
    only: [valid_build_file: 1, filter_sort_builds: 1]

  test "valid_build_file" do
    # acceptable format is version number followed by archive extension
    assert valid_build_file("0.0.1.tar.gz") == true
    assert valid_build_file("1.0.0-alpha.tar.gz") == true
    assert valid_build_file("1.0.0-rc0.tar.gz") == true

    # unexpected filename format
    assert valid_build_file("1.0.0.tgz") == false
    assert valid_build_file("0.0.1") == false

    # invalid versions
    assert valid_build_file("1.0.tar.gz") == false
    assert valid_build_file("1.0.a.tar.gz") == false
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

    assert filter_sort_builds(pretend_files) == [
      "0.0.1-alpha.tar.gz",
      "0.0.1-rc1.tar.gz",
      "0.0.1.tar.gz",
      "1.0.0-10.tar.gz",
      "1.0.1+build0.tar.gz",
      "1.0.1.tar.gz",
      "1.1.0-rc0.tar.gz"
    ]
  end
end