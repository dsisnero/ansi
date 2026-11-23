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
  has a Crystal counterpart, and the audit ledger has no unchecked rows. The
  last feature exposed the width segmentation as `Ansi.each_grapheme_cluster`
  and made the GB9c conjunct merge exact.
- **Next up:**
  1. Re-audit `x/ansi` against upstream `main` and port any new behavior as one
     coherent feature. This is expected to be a no-op while `main` remains
     `cb897cb`.
  2. Extend differential characterization coverage as upstream dependency
     tables advance. Non-GB9c grapheme properties still come from the
     `textseg` shard, which classifies U+0B53 and U+0B54 (unassigned in
     Oriya) as Extend where uax29 does not.
- **Status by area:**
  - Core ANSI sequences and parser: ported.
  - Width measurement: ported; GraphemeWidth uses vendored displaywidth v0.11.0
    tables and WcWidth uses vendored go-runewidth v0.0.27 tables. UAX #29 GB9c
    conjunct segmentation uses vendored InCB tables, and
    `Ansi.each_grapheme_cluster` exposes it to consumers.
  - Colors and conversions: ported.
  - Kitty, iTerm2, and Sixel graphics: ported.
  - Program Status Protocol (OSC 7501): ported from `ansi/v0.11.9`.
  - Quality gates: build, format, lint, and test run locally and in CI across
    the minimum supported Crystal (1.19.1) and latest, with cached dependencies.
    CI builds `bin/ameba` from the shard with `make tools`, so lint no longer
    depends on a system-wide ameba.
- **Scoping notes / gotchas:**
  - The vendored submodule is pinned at `cb897cb` (2026-10-18). The refresh
    checklist and exact diff are in `plans/upstream-refresh-cb897cb.md`.
  - The latest `ansi` tag is `ansi/v0.11.9`; `main` contains later fixes
    (Wcwidth per codepoint, Kitty `Quiet`) that are not in that tag.
  - Width classification uses vendored displaywidth v0.11.0 tables for
    GraphemeWidth and go-runewidth v0.0.27 tables for WcWidth. Single-codepoint
    differential vs Go over U+0000..U+1FFFF is 0 grapheme mismatches and 0
    wcwidth mismatches out of 129,024.
  - `src/incb.cr` vendors the Unicode 17.0.0 Indic_Conjunct_Break tables from
    the same data uax29 v2.7.0 generates from. Segmentation plus cluster widths
    were compared against a Go `FirstGraphemeCluster` loop: 3,450 random
    sequences, 310 hand-picked cases, and every codepoint of the ten Indic
    blocks plus Myanmar and Khmer after a consonant + Linker, with 0
    mismatches for WcWidth and GraphemeWidth.
  - Sixel HLS uses a native port of Go's `colorful.Hsl` plus Go's 16-bit
    rounding, not the Crystal `colorful` shard.
  - `Convert256` uses `Math.fma` to reproduce Go's fused channel arithmetic at
    cube boundaries.
  - Sixel decoder differential fuzzing (200 randomized images) matches Go for
    raster bounds, out-of-bounds pixels, palette definitions, RLE, CR/LF, and
    RLE token consumption.
  - The checkout volume can create AppleDouble `._*` sidecars; run
    `make sidecars` or `make clean` if git or spec discovery misbehaves.
- **Last feature commit:** `port: decode invalid UTF-8 runes as U+FFFD`, which
  follows the grapheme segmentation API commit.
- **Gates:** `make build`, `make format`, `make lint`, `make test` pass
  (517 examples).

## Phase 1 — Core ANSI and parser

- [x] Sequence builders: colors, palette, titles, cursor, modes, mouse,
      clipboard, notifications, hyperlinks, CWD, focus, paste, passthrough, and
      terminal control helpers
- [x] Parser: state machine, transitions, handler API, decode helpers, and the
      supporting Go test port
- [x] Parser invalid UTF-8: `Parser#rune` decodes the collected bytes with
      U+FFFD substitution like Go's `utf8.DecodeRune`, with characterization
      specs verified against the vendored parser

## Phase 2 — Width and colors

- [x] Width model: Wcwidth per codepoint, GraphemeWidth presentation/RI/tag/
      zero-width handling, Unicode 17 tables, Indic GB9c joins, and differential
      coverage against Go
- [x] Grapheme segmentation API: `Ansi.each_grapheme_cluster` yields clusters
      and widths from the same parser loop as `string_width`, backed by
      vendored Indic_Conjunct_Break tables so GB9c boundaries match Go
- [x] Color system: Convert256/Convert16 parity, transparency handling, Color
      conversion helpers, and hex rendering

## Phase 3 — Graphics codecs

- [x] Kitty graphics encoder/decoder, options (`Quiet`/`Quite`), and keyboard
      protocol
- [x] iTerm2 file and inline image support
- [x] Sixel codecs: encoder/decoder edge cases, HLS conversion, palette
      quantization, pdqsort/xorshift, cube heap, writer return values, and
      decoder bounds/RLE parity

## Phase 4 — Upstream refresh and maintenance

- [x] OSC 7501 Program Status Protocol from `ansi/v0.11.9`
- [x] `cb897cb` refresh: Wcwidth per codepoint, Kitty `Quiet`, and dependency
      audit
- [x] Quality gates: build target and GitHub Actions CI
- [ ] Re-audit upstream `main` and port any new behavior as one feature
      (expected no-op while `main` is `cb897cb`)
- [x] Port/vendor `clipperhouse/displaywidth` tables for exact width parity
- [x] Vendor go-runewidth tables for exact WcWidth parity
- [x] CI hardening: supported-Crystal-version matrix and dependency caching

## Intentional divergences

- `ProgramState` and `ProgramStatusKind` are Crystal value structs rather than
  Go named-string types, preserving invalid-value handling while using Crystal
  idioms.
- The Go-compatible `set_program_status` writer delegates to the idiomatic
  `program_status=` writer.
- `GraphemeWidth` applies the UAX #29 GB9c conjunct merge over vendored
  Unicode 17.0.0 Indic_Conjunct_Break tables (`src/incb.cr`), because the
  `textseg` shard does not implement GB9c; width classification comes from the
  vendored displaywidth tables. `WcWidth` follows Go's per-codepoint model.
- `Ansi.each_grapheme_cluster` has no upstream counterpart: Go exposes
  `FirstGraphemeCluster`, a raw one-cluster primitive that leaves ANSI parsing
  to the caller. The Crystal helper walks the whole string with the same parser
  loop as `string_width`, skips escape sequences, and yields each cluster with
  its width so segmentation and measurement cannot drift apart.
