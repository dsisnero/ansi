# Development

See [resuming.md](resuming.md) for the start-of-session checklist and
[../plans/parity.md](../plans/parity.md) for current work.

## Prerequisites

- Crystal `>= 1.19.1`
- `shards`
- Git submodule support for the vendored upstream checkout

## Setup

```bash
git submodule update --init --recursive
make install
make tools
```

`make install` runs `shards install`; `make update` runs `shards update`.
`make tools` builds `bin/ameba` from the ameba development dependency, and
`make lint` uses that binary when it exists so linting does not depend on a
system-wide ameba. Dependencies are recorded in `shard.yml`; `shard.lock` is
intentionally not committed because this is a library.

## Upstream checkout

The upstream Go source is the `vendor/x` submodule:

```bash
git -C vendor/x log -1 --oneline
ls vendor/x/ansi
```

The pinned commit is recorded in `plans/parity.md`. To port a feature that is
newer than the pin, fetch its tag and read the file from that revision without
changing the submodule checkout:

```bash
git -C vendor/x fetch --depth=1 origin refs/tags/ansi/v0.11.10
git -C vendor/x show FETCH_HEAD:ansi/programstatus.go
git -C vendor/x show FETCH_HEAD:ansi/programstatus_test.go
```

Record the tag or commit used for the feature in the plan and commit message.
To check whether the pin is stale, ask upstream what changed under `ansi/`:

```bash
git -C vendor/x log --oneline 8aab43e..origin/main -- ansi
```

A refresh that ports new upstream behavior follows the shape of
[../plans/upstream-refresh-8aab43e.md](../plans/upstream-refresh-8aab43e.md).

## Porting loop

1. Identify the upstream Go file and its tests.
2. Port the tests first and watch them fail for the missing behavior.
3. Implement the smallest Crystal change that matches Go behavior.
4. Run the gates:

   ```bash
   make build
   make format
   make lint
   make test
   make parity
   ```

   `make parity` validates the ledger and the generated manifests against the
   pinned upstream checkout; `make parity-refresh` regenerates the source/test
   snapshots (upstream bump only), and `make parity-reconcile` writes the
   disposable maps under `plans/generated/`.

5. Update the coverage rows in `plans/inventory/go_port_inventory.tsv` (status,
   ref, and a note naming the Crystal symbol), `docs/plan/audit.md`, and the
   **Where we are** block in `plans/parity.md`.
6. Add an `[Unreleased]` entry to `CHANGELOG.md` for anything user visible.
7. Commit one feature atomically using the `port: ...` convention from
   `AGENTS.md`.

CI runs the same gates on the latest Crystal release, with cached
dependencies.

## Temporary files

Use `./temp` for scratch files. `make clean` removes its contents and any
AppleDouble `._*` sidecars created by the filesystem.
