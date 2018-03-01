defmodule Mix.Tasks.Bootleg.Init do
  use Bootleg.MixTask
  require Mix.Generator
  alias Mix.Generator
  alias Bootleg.Tasks

  @shortdoc "Initializes a project for use with Bootleg"

  @moduledoc """
    Initializes a project for use with Bootleg.
  """

  def run(_args) do
    deploy_file_path = Path.join(Tasks.path_deploy_config())
    deploy_dir_path = Path.join(Tasks.path_env_configs())
    production_file_path = Path.join(deploy_dir_path, "production.exs")
    Generator.create_directory("config")
    Generator.create_file(deploy_file_path, deploy_file_text())
    Generator.create_directory(deploy_dir_path)
    Generator.create_file(production_file_path, production_file_text())
  end

  Generator.embed_text(:deploy_file, """
  use Bootleg.Config

  # Configure the following roles to match your environment.
  # `build` defines what remote server your distillery release should be built on.
  #
  # Some available options are:
  #  - `user`: ssh username to use for SSH authentication to the role's hosts
  #  - `password`: password to be used for SSH authentication
  #  - `identity`: local path to an identity file that will be used for SSH authentication instead of a password
  #  - `workspace`: remote file system path to be used for building and deploying this Elixir project

  role :build, "build.example.com", workspace: "/tmp/bootleg/build"

  """)

  Generator.embed_text(:production_file, """
  use Bootleg.Config

  # Configure the following roles to match your environment.
  # `app` defines what remote servers your distillery release should be deployed and managed on.
  #
  # Some available options are:
  #  - `user`: ssh username to use for SSH authentication to the role's hosts
  #  - `password`: password to be used for SSH authentication
  #  - `identity`: local path to an identity file that will be used for SSH authentication instead of a password
  #  - `workspace`: remote file system path to be used for building and deploying this Elixir project

  role :app, ["app1.example.com", "app2.example.com"], workspace: "/var/app/example"

  """)
end
