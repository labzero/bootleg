# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
mix test                    # run all tests
mix test test/ui_test.exs   # run a single test file
mix coveralls               # test with coverage
mix dialyzer                # type checking
mix credo                   # code linting
```

## Architecture

Bootleg is an Elixir deployment automation library. It exposes a macro-based DSL (`Bootleg.DSL`) that users `use` in their `config/deploy.exs` files to describe build/deploy pipelines.

### Core flow

1. **`Bootleg.Config.Agent`** — a named `Agent` process that holds all runtime state: roles, config key/values, and hook registrations. It starts automatically on first access and launches a monitor process that purges dynamically-compiled task/callback modules when the agent dies.

2. **`Bootleg.Tasks`** — loads built-in task files (`lib/bootleg/tasks/**/*.exs`) via `Code.eval_file/1`, then loads third-party task modules (any `Elixir.Bootleg.Tasks.*` module on the code path with a `load/0`), then evaluates `config/deploy.exs` and the env-specific `config/deploy/<env>.exs`.

3. **`Bootleg.DSL`** — the macro layer. `task/2`, `before_task/2`, `after_task/2`, and `invoke/1` compile anonymous task bodies into dynamically-named modules (`Elixir.Bootleg.DynamicTasks.*` / `Elixir.Bootleg.DynamicCallbacks.*`) and register them in the agent. `invoke/1` runs before-hooks → task module → after-hooks in sequence.

4. **`Bootleg.SSH`** — wraps `SSHKit` (Erlang `:ssh`) to open connections, run commands via `run!/2`, and transfer files via `upload/3` / `download/3`. SSH options flow from role options through `ssh_host_options/1`; the `identity:` option is converted to an `SSHClientKeyAPI` key callback.

5. **Built-in tasks** (`lib/bootleg/tasks/`) — plain `.exs` files that `use Bootleg.DSL` and define the standard tasks: `:build` dispatches to `:remote_build` (default), `:local_build`, or `:docker_build` based on the `build_type` config key; `:deploy` uploads/copies the tarball to `:app` role hosts and unpacks it; `:start`/`:stop`/`:restart`/`:ping` run `bin/<app>` commands on `:app` hosts.

6. **Mix tasks** (`lib/mix/tasks/`) — thin wrappers (`use Bootleg.MixTask, :<task_name>`) that parse an optional env argument, set the env on the agent, then call `invoke/1`.

### Key data structures

- **`%Bootleg.Role{}`** — name, user, list of `%Bootleg.Host{}`, keyword options. Roles are stored in the agent under `:roles`.
- **`%Bootleg.Host{}`** — wraps an `%SSHKit.Host{}` plus per-host options.
- Config is a flat keyword list stored under `:config` in the agent; `config/2` merges into it.

### Extension points

- Third-party packages can add tasks by defining a module named `Elixir.Bootleg.Tasks.<Name>` with a `load/0` that calls `Config.load/1` on their own `.exs` file.
- Users override built-in tasks with `task :name, override: true do ... end` or install hooks with `before_task`/`after_task`.

### Config file loading order

`config/deploy.exs` → `config/deploy/<env>.exs` (e.g. `config/deploy/production.exs`)

Both files use `use Bootleg.DSL`. The env defaults to `:production`; pass an env name as the first argument to any mix task (e.g. `mix bootleg.build staging`) to change it.
