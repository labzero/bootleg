
## Deploying from local machine to application server(s)

This is the default behavior of Bootleg. The release archive built on and copied from the build server and stored on the local filesystem, where it is available to copy to application servers.

!!! example "config/deploy.exs"
    ```elixir
    use Bootleg.DSL

    role :build, "build.example.com", workspace: "/home/acme/build"
    role :app, ["app1.example.com", "app2.example.com"], workspace: "/opt/acme"
    ```

## Building and deploying on the same server

The `release_workspace` option specifies where Bootleg should store or locate release archives when using remote servers.

By specifying a `release_workspace` on the `:build` role, the release archive is copied to this location on the remote server after it is built.

By specifying a `release_workspace` on the `:app` role, the release archive is copied from this location to the app workspace.

!!! example "config/deploy.exs"
    ```elixir
    use Bootleg.DSL

    role :build, "acme.example.com", workspace: "/home/acme/build", release_workspace: "/opt/releases"
    role :app, "acme.example.com", workspace: "/opt/acme", release_workspace: "/opt/releases"
    ```

## Options for deploying from build server to application server(s)

Currently there are two ways to have the release archive copied to/from the build server
without needing to download it first.

Both methods described here use the `release_workspace` option to disable the local file download
and set the location where the release archives should be stored.

!!! info "config/deploy.exs"
    ```elixir
    use Bootleg.DSL

    role :build, [...], release_workspace: "/opt/releases"
    role :app, [...], release_workspace: "/opt/releases"
    ```

### Instruct application servers to copy *from* build server

This example requires that the application servers have been configured to non-interactively
connect to the build server using SSH.

???+ example "config/deploy.exs"
    ```elixir
    use Bootleg.DSL
    alias Bootleg.{Config, UI}

    task :copy_release_from_build_server do
      build_path = "user@build.example.com:/opt/releases/#{Config.version()}.tar.gz"
      release_workspace = Config.get_role(:app).options[:release_workspace]

      UI.info("Copying release from build server..")
      remote :app do
        "scp #{build_path} #{release_workspace}"
      end
    end

    after_task(:build, :copy_release_from_build_server)
    ```

### Instruct build server to copy *to* application servers

Another option is to redefine the built-in `copy_deploy_release` task which is executed
as part of the [remote deployment workflow](/reference/workflow.md#deployment-workflow).

This example requires that the build server has been configured to non-interactively
connect to the application servers using SSH.

???+ example "config/deploy.exs"
    ```elixir
    use Bootleg.DSL
    alias Bootleg.{Config, UI}

    task :copy_deploy_release, override: true do
      build_role = Config.get_role(:build)
      version = Config.version()

      build_release_path =
        Path.join(build_role.options[:release_workspace], "#{version}.tar.gz")

      app_role = Config.get_role(:app)
      app_release_path = app_role.options[:release_workspace]

      app_role
      |> Map.get(:hosts)
      |> Enum.each(fn bootleg_host ->
        host_name = bootleg_host.host.name
        UI.info("Copying release archive to #{host_name}")

        command =
          "scp #{build_release_path} #{host_name}:#{app_release_path}"

        IO.puts("-> #{command}")

        remote(:build, do: command)
      end)
    end
    ```
