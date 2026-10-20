# Parity Plan — ansi

Curated feature roadmap for the Crystal port. Keep this file human-curated and
refresh the **Where we are** block after every feature. Per-symbol coverage
lives in [`docs/plan/audit.md`](../docs/plan/audit.md).

## Where we are

- **Current focus:** finish
  [`plans/upstream-refresh-cb897cb.md`](upstream-refresh-cb897cb.md). Wcwidth
  per codepoint and the Kitty `Quiet` rename are complete; the dependency audit
  is next.
- **Next up:**
  1. Audit Crystal width dependencies against the upstream `go.mod` bumps and
     record any intentional shard-version divergences.
  2. Fix HSL conversion accuracy in Sixel so pure colors match Go.
  3. Add the missing Sixel palette quantization tests.
  4. Port the remaining color tests and extend `Color` functionality.
  5. Implement the remaining Sixel decoder behavior and `FullImage` tests.
  6. Re-audit `x/ansi` against the next newer upstream tag and add missing
     behavior.
- **Status by area:**
  - Core ANSI sequences (colors, styles, cursor, modes, mouse, clipboard,
    notifications, hyperlinks, terminal reports): ported.
  - Parser, transitions, decode helpers, handlers: ported.
  - Width measurement: ported — `WcWidth` sums per-codepoint widths;
    `GraphemeWidth` matches the refreshed Go tests.
  - Kitty and iTerm2 graphics: ported, including the `Quiet` rename with the
    deprecated `Quite` compatibility field.
  - Sixel: in progress — decoder and palette quantization have gaps.
  - Program Status Protocol (OSC 7501): ported from `ansi/v0.11.9`.
- **Scoping notes / gotchas:**
  - The vendored submodule is now pinned at `cb897cb` (2026-10-18). The refresh
    checklist and exact diff are in `plans/upstream-refresh-cb897cb.md`.
  - The latest `ansi` tag is `ansi/v0.11.9`; `main` contains later fixes
    (Wcwidth per codepoint, Kitty `Quiet`) that are not in that tag.
  - `sixel/palette_test.go` and `parser_test.go` contain Go test-only helper
    structs that are not API surface; the audit marks them unchecked.
  - The checkout volume can create AppleDouble `._*` sidecars; run
    `make sidecars` or `make clean` if git or spec discovery misbehaves.
- **Last commit:** `e661202` (port: kitty Quiet option)
- **Gates:** `make lint` pass; `make test` pass (407 examples).

## Phase 1 — Core ANSI and parser parity

- [x] Colors, styles, SGR, terminal reports
- [x] Cursor, keypad, modes, mouse, focus
- [x] Clipboard, notifications, hyperlinks, CWD, passthrough
- [x] Parser state machine, transitions, decode helpers
- [x] Broad Go test port for parser and core sequences

## Phase 2 — Graphics codecs

- [x] Kitty graphics encoder/decoder and options
- [x] iTerm2 file and inline image support
- [ ] Sixel decoder functionality and `FullImage` tests
- [ ] Sixel palette quantization tests
- [ ] Sixel HSL conversion accuracy

## Phase 3 — Newer upstream features

- [x] Program Status Protocol (OSC 7501) from `ansi/v0.11.9`
- [x] Port Wcwidth per codepoint from the `cb897cb` refresh
- [x] Port the Kitty `Quiet` option rename from the `cb897cb` refresh
- [ ] Audit width dependencies against the refreshed upstream `go.mod`
- [ ] Re-audit `x/ansi` against the next newer upstream tag and add missing
      behavior

## Intentional divergences

- Sixel palette sorting uses a deterministic Crystal sort instead of the Go
  xorshift priority queue; the resulting color selection is intended to match.
- `ProgramState` and `ProgramStatusKind` are Crystal value structs rather than
  Go named-string types, preserving invalid-value handling while using Crystal
  idioms.
- The Go-compatible `set_program_status` writer delegates to the idiomatic
  `program_status=` writer.
- `GraphemeWidth` carries a targeted UAX #29 GB9c merge for major Indic viramas
  and a supplemental wide-emoji fallback because the Crystal width shards lag
  Go's `displaywidth` tables. `WcWidth` follows Go's per-codepoint model.
