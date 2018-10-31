
# Mix Tasks

## Management commands

Bootleg has a set of commands to check up on your running nodes:

```console
mix bootleg.restart production   # Restarts a deployed release.
mix bootleg.start production     # Starts a deployed release.
mix bootleg.stop production      # Stops a deployed release.
mix bootleg.ping production      # Check status of running nodes
```

## Build and deployment commands

```console
mix bootleg.build production
mix bootleg.deploy production
mix bootleg.start production
```

Alternatively the above commands can be rolled into one with:

```console
mix bootleg.update production
```

!!! info
    The `bootleg.update` will stop any running nodes and then perform a cold start. The stop is performed with the task `stop_silent`, which differs from `stop` in that it does not fail if the node is already stopped.


