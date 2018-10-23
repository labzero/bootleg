## Build Workflows
> Entry point `:build`, or `mix bootleg.build`

### Remote Builds
- `verify_config`
- `build`
- `remote_verify_config`
- `remote_build`
- `init`
- `clean`
- `remote_scm_update`
    - `git_mode == pull?`
        - `verify_repo_config`
        - `pull_remote`
    - `git_mode == push?`
        - `push_remote`
        - `reset_remote`
- `compile`
- `release_workspace set?`
    - `yes`
        - `copy_build_release`
    - `no`
        - `download_release`

### Local Builds
- `verify_config`
- `build`
- `local_verify_config`
- `local_build`
- `local_compile`
- `local_copy_release`

### Docker Builds
- `verify_config`
- `build`
- `docker_verify_config`
- `docker_build`
- `docker_compile`
- `docker_copy_release`

## Deployment Workflow
> Entry point `:deploy`, or `mix bootleg.deploy`

- `deploy`
- `release_workspace set?`
    - `yes`
        - `copy_deploy_release`
    - `no`
        - `upload_release`
- `unpack_release`

## Update Workflow
> Entry point `:update`, or `mix bootleg.update`

- `update`
- `build`
- `deploy`
- `stop_silent`
- `start`
