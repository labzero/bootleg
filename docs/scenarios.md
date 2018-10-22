Although the authors would like to support every type of build and deployment scenario, focus remains on remote build, remote deploy.

That said, the following scenarios are all possible using Bootleg:

## Building on your local machine

- You can build directly on your workstation
- You can build within a Docker image

## Building on a remote machine

- Code is delivered to the server using the local Git client to do a push with `git+ssh`
    - Requires non-interactive SSH access or special passphrase considerations
- Remote server obtains the code via Git pull from the repository using its Git client
- Build server is also the application server
    - Instead of downloading the release, and then uploading it, we can just copy the release

## Deploying

- Application is served by one or more remote machines
