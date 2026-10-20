# Parity Plan — ansi

Curated feature roadmap for the Crystal port. Keep this file human-curated and
refresh the **Where we are** block after every feature. Per-symbol coverage
lives in [`docs/plan/audit.md`](../docs/plan/audit.md).

Each checkbox is one shippable, feature-sized commit. A feature may span
several files and upstream tests; batch related behavior, tests, audit rows,
and plan updates into that commit. Do not split one feature into per-edge-case
micro-commits.

## Where we are

- **Current focus:** maintenance. Every upstream file in the pinned checkout
  has a Crystal counterpart, and the audit ledger has no unchecked rows.
- **Next up:**
  1. Re-audit `x/ansi` against upstream `main` and port any new behavior as one
     coherent feature. This is expected to be a no-op while `main` remains
     `cb897cb`.
  2. Port/vendor `clipperhouse/displaywidth` tables as one feature if exact
     width parity becomes a requirement.
  3. Extend differential characterization coverage as upstream dependency
     tables advance.
- **Status by area:**
  - Core ANSI sequences and parser: ported.
  - Width measurement: ported with Unicode 17 tables plus targeted fallbacks.
  - Colors and conversions: ported.
  - Kitty, iTerm2, and Sixel graphics: ported.
  - Program Status Protocol (OSC 7501): ported from `ansi/v0.11.9`.
  - Quality gates: build, format, lint, and test run locally and in CI across
    the minimum supported Crystal (1.19.1) and latest, with cached dependencies.
- **Scoping notes / gotchas:**
  - The vendored submodule is pinned at `cb897cb` (2026-10-18). The refresh
    checklist and exact diff are in `plans/upstream-refresh-cb897cb.md`.
  - The latest `ansi` tag is `ansi/v0.11.9`; `main` contains later fixes
    (Wcwidth per codepoint, Kitty `Quiet`) that are not in that tag.
  - Width uses `unicode_width` (Unicode 17) for wide-rune classification and
    `uniwidth` for combining-mark and East Asian Ambiguous handling.
    Single-codepoint differential vs Go over U+0000..U+1FFFF is 84 grapheme
    mismatches and 1 wcwidth mismatch out of 129,024; most leftovers are newer
    combining marks where this port has newer Unicode data.
  - Sixel HLS uses a native port of Go's `colorful.Hsl` plus Go's 16-bit
    rounding, not the Crystal `colorful` shard.
  - `Convert256` uses `Math.fma` to reproduce Go's fused channel arithmetic at
    cube boundaries.
  - The checkout volume can create AppleDouble `._*` sidecars; run
    `make sidecars` or `make clean` if git or spec discovery misbehaves.
- **Last feature commit:** `505ff26` (port: sixel FromColor nil parity)
- **Gates:** `make build`, `make format`, `make lint`, `make test` pass
  (462 examples).

## Phase 1 — Core ANSI and parser

- [x] Sequence builders: colors, palette, titles, cursor, modes, mouse,
      clipboard, notifications, hyperlinks, CWD, focus, paste, passthrough, and
      terminal control helpers
- [x] Parser: state machine, transitions, handler API, decode helpers, and the
      supporting Go test port

## Phase 2 — Width and colors

- [x] Width model: Wcwidth per codepoint, GraphemeWidth presentation/RI/tag/
      zero-width handling, Unicode 17 tables, Indic GB9c joins, and differential
      coverage against Go
- [x] Color system: Convert256/Convert16 parity, transparency handling, Color
      conversion helpers, and hex rendering

## Phase 3 — Graphics codecs

- [x] Kitty graphics encoder/decoder, options (`Quiet`/`Quite`), and keyboard
      protocol
- [x] iTerm2 file and inline image support
- [x] Sixel codecs: encoder/decoder edge cases, HLS conversion, palette
      quantization, pdqsort/xorshift, cube heap, and writer return values

## Phase 4 — Upstream refresh and maintenance

- [x] OSC 7501 Program Status Protocol from `ansi/v0.11.9`
- [x] `cb897cb` refresh: Wcwidth per codepoint, Kitty `Quiet`, and dependency
      audit
- [x] Quality gates: build target and GitHub Actions CI
- [ ] Re-audit upstream `main` and port any new behavior as one feature
      (expected no-op while `main` is `cb897cb`)
- [ ] Port/vendor `clipperhouse/displaywidth` tables for exact width parity
      (only if required)
- [x] CI hardening: supported-Crystal-version matrix and dependency caching

## Intentional divergences

- `ProgramState` and `ProgramStatusKind` are Crystal value structs rather than
  Go named-string types, preserving invalid-value handling while using Crystal
  idioms.
- The Go-compatible `set_program_status` writer delegates to the idiomatic
  `program_status=` writer.
- `GraphemeWidth` carries a targeted UAX #29 GB9c merge for major Indic viramas
  and supplemental Unicode 17 width handling where Go's tables are older.
  `WcWidth` follows Go's per-codepoint model.
