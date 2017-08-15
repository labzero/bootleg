defmodule Mix.Tasks.Bootleg.Init do
  use Bootleg.MixTask
  require Mix.Generator
  alias Mix.Generator

  @shortdoc "Initializes a project for use with Bootleg"

  @moduledoc """
    Initializes a project for use with Bootleg.
  """

  def run(_args) do
    deploy_file_path = Path.join(["config", "deploy.exs"])
    deploy_dir_path = Path.join(["config", "deploy"])
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

  # Phoenix has some extra build steps such as asset digesting that need to be done during
  # compilation. To have bootleeg handle that for you, include the additional package
  # `bootleg_phoenix` to your `deps` list. This will automatically perform the additional steps
  # required for building phoenix releases.
  #
  #  ```
  #  # mix.exs
  #  def deps do
  #    [{:distillery, "~> 1.3"},
  #    {:bootleg, "~> 0.3"},
  #    {:bootleg_phoenix, "~> 0.1"}]
  #  end
  #  ```
  # For more about `bootleg_phoenix` see: https://github.com/labzero/bootleg_phoenix

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
