# Parity Plan — ansi

Curated feature roadmap for the Crystal port. Keep this file human-curated and
refresh the **Where we are** block after every feature. Per-symbol coverage
lives in [`docs/plan/audit.md`](../docs/plan/audit.md).

## Where we are

- **Current focus:** port the remaining Sixel parity work. The upstream refresh
  is complete: Wcwidth, Kitty `Quiet`, the dependency audit, Sixel HSL
  accuracy, and palette quantization tests are done.
- **Next up:**
  1. Port the remaining color tests and extend `Color` functionality.
  2. Implement the remaining Sixel decoder behavior and `FullImage` tests.
  3. Re-audit `x/ansi` against the next newer upstream tag and add missing
     behavior.
- **Status by area:**
  - Core ANSI sequences (colors, styles, cursor, modes, mouse, clipboard,
    notifications, hyperlinks, terminal reports): ported.
  - Parser, transitions, decode helpers, handlers: ported.
  - Width measurement: ported — `WcWidth` sums per-codepoint widths;
    `GraphemeWidth` matches the refreshed Go tests.
  - Kitty and iTerm2 graphics: ported, including the `Quiet` rename with the
    deprecated `Quite` compatibility field.
  - Sixel: HSL conversion and palette quantization tests now match Go; decoder
    and `FullImage` behavior still have gaps.
  - Program Status Protocol (OSC 7501): ported from `ansi/v0.11.9`.
- **Scoping notes / gotchas:**
  - The vendored submodule is now pinned at `cb897cb` (2026-10-18). The refresh
    checklist and exact diff are in `plans/upstream-refresh-cb897cb.md`.
  - The latest `ansi` tag is `ansi/v0.11.9`; `main` contains later fixes
    (Wcwidth per codepoint, Kitty `Quiet`) that are not in that tag.
  - Crystal `uniwidth`/`uni_text_seg` are already at their latest tags
    (0.1.3), which lag Go's `displaywidth`/`uax29`; the width fallbacks and
    GB9c virama merge stay in-repo until those shards update.
  - Sixel HLS uses a native port of Go's `colorful.Hsl` plus Go's 16-bit
    rounding, not the Crystal `colorful` shard.
  - `sixel/palette_test.go` and `parser_test.go` contain Go test-only helper
    structs that are not API surface; the audit marks them unchecked.
  - The checkout volume can create AppleDouble `._*` sidecars; run
    `make sidecars` or `make clean` if git or spec discovery misbehaves.
- **Last commit:** `cffdfe2` (port: sixel HLS conversion accuracy)
- **Gates:** `make lint` pass; `make test` pass (412 examples).

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
- [x] Sixel palette quantization tests
- [x] Sixel HSL conversion accuracy

## Phase 3 — Newer upstream features

- [x] Program Status Protocol (OSC 7501) from `ansi/v0.11.9`
- [x] Port Wcwidth per codepoint from the `cb897cb` refresh
- [x] Port the Kitty `Quiet` option rename from the `cb897cb` refresh
- [x] Audit width dependencies against the refreshed upstream `go.mod`
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
