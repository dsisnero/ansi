# ansi

> **How to resume:** read [plans/parity.md](plans/parity.md) first and use its
> **Where we are** block (current focus + ordered "Next up"), then run
> `make lint` and `make test`. Details: [docs/resuming.md](docs/resuming.md).
> Do not re-derive state from git history.

Crystal port of `charmbracelet/x/ansi` (Go) from
[charmbracelet/x](https://github.com/charmbracelet/x), vendored at `x/ansi`
(commit `cb897cb`). The Go implementation is the source of truth. The port also
tracks newer upstream files when a feature is requested, for example OSC 7501
program status from `ansi/v0.11.9`.

## Commands

```bash
make install   # shards install
make update    # shards update
make build     # crystal build --no-codegen src/ansi.cr
make format    # crystal tool format --check src spec
make lint      # ameba --fix src spec, then ameba src spec
make test      # crystal spec
make clean     # remove ./temp contents and AppleDouble sidecars
```

## Docs

- [Resuming work](docs/resuming.md)
- [Architecture](docs/architecture.md)
- [Development](docs/development.md)
- [Coding Guidelines](docs/coding-guidelines.md)
- [Testing](docs/testing.md)
- [PR Workflow](docs/pr-workflow.md)
- [Parity plan](plans/parity.md)
- [Port audit](docs/plan/audit.md)

## Principles

1. Upstream behavior under `x/ansi` is the source of truth and wins over local
   preference.
2. Port behavior, not style. Use Crystal idioms only where behavior is
   unchanged.
3. Port upstream tests early and never weaken assertions.
4. Track parity in [plans/parity.md](plans/parity.md) and per-symbol coverage in
   [docs/plan/audit.md](docs/plan/audit.md).
5. Commit one completed feature at a time.

## Session continuity (read this first)

`plans/parity.md` is the single source of truth for where we are. At the start
of every session:

1. Read `plans/parity.md` and use its **Where we are** block to find the current
   focus, the ordered "Next up" list, and per-area status. Do not re-derive
   state from git history.
2. Skim `git log --oneline -10` and `git status` to confirm the working tree.
3. Run `make lint` and `make test` before changes to confirm a clean baseline.

See [docs/resuming.md](docs/resuming.md) for the full resume checklist.

### Keeping `plans/parity.md` resumable

- `plans/parity.md` starts with a **Where we are** block (`Current focus`,
  `Next up`, status by area, gotchas, last commit, gates). Refresh it before
  every commit and before ending a session.
- Work items are feature-sized (roughly one branch/commit). Per-symbol state
  lives in `docs/plan/audit.md`, not in the plan.
- If `plans/parity.md` grows too large, split areas into
  `plans/parity/<area>.md` files, link each from `plans/parity.md`, and
  mark each split file complete/in-progress plus the area being worked on
  next.

### Definition of done for every feature (required)

A feature is complete only when all of the following are true, and all of it
must be committed as **one** atomic commit before starting the next feature:

1. the API surface is implemented;
2. upstream tests (or equivalent characterization specs) exist and pass;
3. gates pass: `make lint` and `make test`;
4. coverage rows for the feature are updated in `docs/plan/audit.md`;
5. `plans/parity.md` status is updated and the **Where we are** block refreshed
   (current focus + next up);
6. any intentional divergence is documented (in `plans/parity.md` and/or the
   commit message).

### Commit message

Start with `port:` and a one-line feature name, then bullets for what changed,
then the upstream revision (`charmbracelet/x` `cb897cb`, or the newer tag used
for the feature). Include new/changed files, divergences, and gate results so a
new session can resume from the commit alone.

## Crystal development guidelines

Follow Crystal idioms while preserving Go behavior:

- Use `crystal tool format` and `ameba`; do not leave formatting or lint
  failures behind.
- Use `snake_case` for methods and variables, `CamelCase` for types, and
  `UPPER_SNAKE_CASE` only for constants that are genuinely constant.
- Prefer Crystal's standard library over custom implementations.
- Use Crystal's type system effectively; avoid unnecessary `as` casts.
- Keep one source file per upstream Go file where practical, and add the
  `require` in `src/ansi.cr`.
- Document public types and methods with comments that name the upstream
  behavior or escape sequence.
- When a Go API named `SetFoo` is part of the public contract, expose the
  Crystal-idiomatic `foo=` writer and keep `set_foo` as a delegating
  compatibility method. Do not silence `Naming/AccessorMethodName`; only use
  `# ameba:disable` for rules such as complexity where the port needs the
  upstream control flow.

### Test porting guidelines

When porting Go tests to Crystal specs:

1. **Port test logic exactly** — do not adjust assertions or expected values.
2. **Use Crystal idioms for structure** — convert Go test tables to Crystal
   `it` blocks or data-driven loops.
3. **Mark blocked functionality as pending** — use `pending` with the blocking
   issue or reason; never delete the assertion.
4. **Keep the same coverage and edge cases** as the upstream test.
5. **Verify against the Go implementation** — the Crystal behavior must match.

## File system guidelines

- Use `./temp` for temporary files created during testing or development.
- Never commit temporary files (`temp/` and `tmp/` are ignored).
- `make clean` removes `./temp` contents and AppleDouble sidecars.
- Do not edit vendored upstream code under `x/`; treat it as read-only source of
  truth.

## Environment notes

This checkout may live on a volume that writes AppleDouble `._*` sidecars
(for example `._shard.lock` or `._pack-*.idx`). They break test discovery and
produce `non-monotonic index` errors from git. `make clean` and the `sidecars`
target remove them; the `format`, `lint`, and `test` targets run `sidecars`
first.
