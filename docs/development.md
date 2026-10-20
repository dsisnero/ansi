# Development

See [resuming.md](resuming.md) for the start-of-session checklist and
[../plans/parity.md](../plans/parity.md) for current work.

## Prerequisites

- Crystal `>= 1.19.1`
- `shards`
- `ameba` (installed as a development dependency)
- Git submodule support for the vendored upstream checkout

## Setup

```bash
git submodule update --init --recursive
make install
```

`make install` runs `shards install`; `make update` runs `shards update`.
Dependencies are recorded in `shard.yml`; `shard.lock` is intentionally not
committed because this is a library.

## Upstream checkout

The upstream Go source is the `x` submodule:

```bash
git -C x log -1 --oneline
ls x/ansi
```

The pinned commit is recorded in `plans/parity.md`. To port a feature that is
newer than the pin, fetch its tag and read the file from that revision without
changing the submodule checkout:

```bash
git -C x fetch --depth=1 origin refs/tags/ansi/v0.11.9
git -C x show FETCH_HEAD:ansi/programstatus.go
git -C x show FETCH_HEAD:ansi/programstatus_test.go
```

Record the tag or commit used for the feature in the plan and commit message.

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
   ```

5. Update `docs/plan/audit.md` and the **Where we are** block in
   `plans/parity.md`.
6. Commit one feature atomically using the `port: ...` convention from
   `AGENTS.md`.

## Temporary files

Use `./temp` for scratch files. `make clean` removes its contents and any
AppleDouble `._*` sidecars created by the filesystem.
