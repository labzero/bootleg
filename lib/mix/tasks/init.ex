defmodule Mix.Tasks.Bootleg.Init do
  use Bootleg.Task
  require Mix.Generator
  alias Mix.Generator

  @shortdoc "Initializes a project for use with Bootleg"

  @moduledoc """
    Initializes a project for use with Bootleg.
  """

  def run(_args) do
    deploy_file_path = Path.join(["config", "deploy.exs"])
    Generator.create_directory("config")
    Generator.create_file(deploy_file_path, deploy_file_text())
  end

  Generator.embed_text(:deploy_file, """
  use Bootleg.Config

  # Configure the following roles to match your environment.
  # `build` defines what remote server your distillery release should be built on.
  # `app` defines what remote servers your distillery release should be deployed and managed on.
  #
  # Some available options are:
  #  - `user`: ssh username to use for SSH authentication to the role's hosts
  #  - `password`: password to be used for SSH authentication
  #  - `identity`: local path to an identity file that will be used for SSH authentication instead of a password
  #  - `workspace`: remote file system path to be used for building and deploying this Elixir project

  role :build, "build.example.com", workspace: "/tmp/bootleg/build"
  role :app, ["app1.example.com", "app2.example.com"], workspace: "/var/app/example"

  # Phoenix has some extra build steps which can be defined as task after the compile step runs.
  #
  # Uncomment the following task definition if this is a Phoenix application. To learn more about 
  # hooks and adding additional behavior to your deploy workflow, please refer to the bootleg 
  # README which can be found at https://github.com/labzero/bootleg/blob/master/README.md

  # after_task :compile do
  #   remote :build do
  #     "[ -f package.json ] && npm install || true"
  #     "[ -f brunch-config.js ] && [ -d node_modules ] && ./node_modules/brunch/bin/brunch b -p || true"
  #     "[ -d deps/phoenix ] && mix phoenix.digest || true"
  #   end
  # end
  """)

end
