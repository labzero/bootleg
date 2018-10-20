
When deploying a Phoenix application you will typically want to build your assets after the compilation of your application but before packaging it into a Distillery release.

### Write your own task to hook into the build workflow

You can write a task to run after the `:compile` task, and compile the assets yourself. See also [hooking into tasks](/config/tasks.md#hooking-into-built-in-bootleg-tasks).

### Use the provided `bootleg_phoenix` package

You may wish to use the [bootleg_phoenix](https://github.com/labzero/bootleg_phoenix) package to automatically compile Phoenix assets in remote builds.
