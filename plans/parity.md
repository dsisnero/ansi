# Parity Plan — ansi

Curated feature roadmap for the Crystal port. Keep this file human-curated and
refresh the **Where we are** block after every feature. Per-symbol coverage
lives in [`docs/plan/audit.md`](../docs/plan/audit.md).

## Where we are

- **Current focus:** differential coverage and upstream watching. Width now uses
  Unicode 17 tables; remaining single-codepoint differences are a small set of
  combining marks where this port is newer than Go's tables.
- **Next up:**
  1. Re-audit `x/ansi` against upstream `main` (currently `cb897cb` is still
     the latest) and refresh the vendor pin/plan when it moves.
  2. Keep differential color/width checks running as `unicode_width`,
     `displaywidth`, and `uax29` tables advance.
  3. Decide whether to vendor/port `clipperhouse/displaywidth` if exact parity
     with Go's tables becomes a hard requirement.
- **Status by area:**
  - Core ANSI sequences (colors, styles, cursor, modes, mouse, clipboard,
    notifications, hyperlinks, terminal reports): ported.
  - Parser, transitions, decode helpers, handlers: ported; test helpers
    reconciled in the audit.
  - Width measurement: ported — `WcWidth` sums per-codepoint widths;
    `GraphemeWidth` uses Unicode 17 wide tables plus displaywidth-compatible
    text-presentation, RI, zero-width mark, and grapheme handling.
  - Kitty and iTerm2 graphics: ported, including the `Quiet` rename with the
    deprecated `Quite` compatibility field.
  - Color conversions: ported — `Convert256` matches Go across a 140,608-color
    differential grid; alpha-zero colors map to index 0; `Convert16` covers
    every palette color type; `Color` exposes hex/RGB/true-color/alpha/indexed/
    basic conversion helpers and renders as `#rrggbb`.
  - Sixel: encoder, decoder, palette quantization, HSL conversion, palette
    segment sorting (pdqsort + xorshift), and cube priority queue all match Go;
    nil and zero-size images follow upstream output semantics.
  - Program Status Protocol (OSC 7501): ported from `ansi/v0.11.9`.
  - Repository quality gates: `make build`, format, lint, and test run in
    GitHub Actions.
- **Scoping notes / gotchas:**
  - The vendored submodule is now pinned at `cb897cb` (2026-10-18). The refresh
    checklist and exact diff are in `plans/upstream-refresh-cb897cb.md`.
  - The latest `ansi` tag is `ansi/v0.11.9`; `main` contains later fixes
    (Wcwidth per codepoint, Kitty `Quiet`) that are not in that tag.
  - Width uses `unicode_width` (Unicode 17) for wide-rune classification and
    `uniwidth` for combining-mark and East Asian Ambiguous handling.
    Single-codepoint differential vs Go over U+0000..U+1FFFF is now 84
    grapheme mismatches and 1 wcwidth mismatch out of 129,024; most leftovers
    are newer combining marks where this port has newer Unicode data.
  - Sixel HLS uses a native port of Go's `colorful.Hsl` plus Go's 16-bit
    rounding, not the Crystal `colorful` shard.
  - `Convert256` uses `Math.fma` to reproduce Go's fused channel arithmetic at
    cube boundaries.
  - The checkout volume can create AppleDouble `._*` sidecars; run
    `make sidecars` or `make clean` if git or spec discovery misbehaves.
- **Last commit:** `3e63b7b` (chore: add build gate and CI)
- **Gates:** `make lint` pass; `make test` pass (455 examples).

## Phase 1 — Core ANSI and parser parity

- [x] Colors, styles, SGR, terminal reports
- [x] Cursor, keypad, modes, mouse, focus
- [x] Clipboard, notifications, hyperlinks, CWD, passthrough
- [x] Parser state machine, transitions, decode helpers
- [x] Broad Go test port for parser and core sequences

## Phase 2 — Graphics codecs

- [x] Kitty graphics encoder/decoder and options
- [x] iTerm2 file and inline image support
- [x] Sixel decoder functionality and `FullImage` tests
- [x] Sixel palette quantization tests
- [x] Sixel HSL conversion accuracy
- [x] Remaining color tests and `Convert256` boundary parity

## Phase 3 — Newer upstream features

- [x] Program Status Protocol (OSC 7501) from `ansi/v0.11.9`
- [x] Port Wcwidth per codepoint from the `cb897cb` refresh
- [x] Port the Kitty `Quiet` option rename from the `cb897cb` refresh
- [x] Audit width dependencies against the refreshed upstream `go.mod`
- [ ] Re-audit `x/ansi` against the next newer upstream tag and add missing
      behavior

## Intentional divergences

- `ProgramState` and `ProgramStatusKind` are Crystal value structs rather than
  Go named-string types, preserving invalid-value handling while using Crystal
  idioms.
- The Go-compatible `set_program_status` writer delegates to the idiomatic
  `program_status=` writer.
- `GraphemeWidth` carries a targeted UAX #29 GB9c merge for major Indic viramas
  and a supplemental wide-emoji fallback because the Crystal width shards lag
  Go's `displaywidth` tables. `WcWidth` follows Go's per-codepoint model.
