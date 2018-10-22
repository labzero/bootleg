## List of Bootleg options

### Common

| Option       | Description                                                                                             | Default            |
|:-------------|:--------------------------------------------------------------------------------------------------------|:-------------------|
| `app`        | The OTP application name.                                                                               | Project `app_name` |
| `version`    | The application version to build.                                                                       | Project `version`  |
| `env`        | Sets or overrides the Bootleg environment.                                                              | `#!elixir "production"`       |
| `mix_env` | Overrides the Mix environment. | `#!elixir "prod"` |
| `build_type` | Specifies which build strategy to use, from: `#!elixir :local`, `#!elixir :docker`, `#!elixir :remote`. | `#!elixir :remote` |
| `release_args` | List of arguments to pass to `mix release` | `#!elixir ["--quiet"]` |

### Miscellaneous

| Option              | Description                                                                                                                                                                                                                                                                                      | Default                |
|:--------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------|
| `ex_path`           | Base path to the project. If your Mix project is not at the top level of your repository (e.g. if using pango or an umbrella application), this can be used to point Bootleg at where the build should take place. (Most applicable to remote build servers.)                                                                                                              | `#!elixir File.cwd!/0` |
| `clean_locations` | For remote builds, a list of locations can be specified that should be cleaned (files deleted) in the `clean` task. | `*` |


### Source code management

| Option     | Description                                                                                                                                                                 | Default          |
|:-----------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------|
| `refspec`  | The Git refspec to use for push operations to remote build servers.                                                                                                         | `"master"`       |
| `git_mode` | Which Git strategy to use for remote build servers.<br>`:push` effects a `git push` to your build server<br>`:pull` will attempt to do a `git pull` from your build server. | `#!elixir :push` |
| `repo_url` | The Git repository URL. Required when setting `git_mode` to `:pull`.                                                                                                        | `#!elixir nil`   |

### Docker configuration

| Option               | Description                                                                           | Default                                  |
|:---------------------|:--------------------------------------------------------------------------------------|:-----------------------------------------|
| `docker_build_image` | The name of the Docker image to use. Required when setting `build_type` to `:docker`. | `#!elixir nil`                           |
| `docker_build_opts`  | An optional list of additional arguments to pass when executing `docker run`.         | `#!elixir []`                            |
| `docker_build_mount` | An optional mount configuration to use when executing `docker run`.                   | Mounts current directory as `/opt/build` |


