# Parity Plan — ansi

Curated feature roadmap for the Crystal port. Keep this file human-curated and
refresh the **Where we are** block after every feature. Per-symbol coverage
lives in [`docs/plan/audit.md`](../docs/plan/audit.md).

Each checkbox is one shippable, feature-sized commit. A feature may span
several files and upstream tests; batch related behavior, tests, audit rows,
and plan updates into that commit. Do not split one feature into per-edge-case
micro-commits.

## Where we are

- **Current focus:** maintenance plus parity-tooling adoption. Every upstream
  file in the pinned checkout has a Crystal counterpart and the hand-verified
  audit ledger has no unchecked rows. The last feature removed the quadratic
  cost in the per-cluster path: `first_grapheme_cluster` now segments a lookahead
  window instead of the whole remaining suffix (the `textseg` shard's
  `Graphemes#initialize` decodes all of its input), and printable ASCII
  short-circuits without segmentation like `uax29`'s own hot path.
  `Ansi.string_width` on 8 000 ASCII characters went from ~50 s to ~1 ms, and a
  3.2 KB mixed string from 6.3 s to 45 ms. The machine-checked ledger was then
  bootstrapped; curating it is the open work. The upstream checkout also moved to
  the repository-standard `vendor/x` submodule path (`vendor/x/ansi`), which is
  what every document and the parity tooling now reference.
- **Next up:**
  1. Curate `plans/inventory/go_port_inventory.tsv`. Reconciliation with no
     rules maps 618 source entities (317 matched, 81 ambiguous, 220 unmapped),
     and coarse name normalization finds 344 Crystal counterparts out of 1 314,
     so the gap is mostly rename rules (Go `String()` → `to_s`,
     `SetFoo` → `foo=` / `set_foo`, ALL-CAPS cursor and mode helpers) and
     upstream test helpers that the source scope pulls in. Add
     `plans/parity_rules.yml`, exclude test helpers from the inventory scope, and
     move the `docs/plan/audit.md` rows into the ledger one area at a time,
     starting with `width.go` / `wcwidth.go` / `parser_decode.go`.
  2. Re-audit `vendor/x/ansi` against upstream `main` and port any new behavior
     as one coherent feature. This is expected to be a no-op while `main`
     remains `cb897cb`.
  3. Close the remaining segmentation divergence: the `textseg` shard breaks
     `GB9b` between two `Prepend` code points (`U+0600 U+0600`), which `uax29`
     keeps in one cluster. Found by the lookahead differential below; 2 of
     7 571 cases. Fixing it means either extending the shard's GB9b table locally
     or folding the prepend run in `first_grapheme_cluster`, the way GB9c is
     folded.
  4. Extend differential characterization coverage as upstream dependency
     tables advance. Non-GB9c grapheme properties still come from the
     `textseg` shard, which classifies U+0B53 and U+0B54 (unassigned in
     Oriya) as Extend where uax29 does not.
- **Status by area:**
  - Core ANSI sequences and parser: ported.
  - Width measurement: ported, and linear in the input. GraphemeWidth uses
    vendored displaywidth v0.11.0 tables and WcWidth uses vendored go-runewidth
    v0.0.27 tables. UAX #29 GB9c conjunct segmentation uses vendored InCB
    tables, and `Ansi.each_grapheme_cluster` exposes it to consumers. The
    first cluster of a suffix is found from a 32-byte lookahead window (doubling
    for longer clusters) and printable ASCII never reaches the segmenter.
  - Colors and conversions: ported.
  - Kitty, iTerm2, and Sixel graphics: ported.
  - Program Status Protocol (OSC 7501): ported from `ansi/v0.11.9`.
  - Quality gates: build, format, lint, and test run locally and in CI on the
    latest Crystal release, with cached dependencies. CI builds `bin/ameba`
    from the shard with `make tools`, so lint does not depend on a system-wide
    ameba. The minimum supported Crystal (1.19.1) is checked by hand before a
    release rather than in every run.
  - Parity tooling: adopted from the installed `cross-language-crystal-parity`
    skill. `plans/inventory/` holds the curated ledger
    `go_port_inventory.tsv` (1 314 declarations: 838 consts, 279 functions,
    138 methods, 33 types, 20 classes, 6 interfaces) plus generated
    `go_source_parity.tsv` / `go_test_parity.tsv` snapshots with their
    `.metadata.json`. `make parity` re-validates all three against
    `vendor/x/ansi` with the tree-sitter backend; `make parity-refresh` is for
    an upstream bump only; `make parity-reconcile` writes the disposable bundle
    under `plans/generated/` (gitignored). The ledger is bootstrapped, not
    curated: its rows are all `missing`, so it is a to-do list, not a coverage
    claim.
- **Scoping notes / gotchas:**
  - The vendored submodule is pinned at `cb897cb` (2026-10-18) and lives at
    `vendor/x` (the `charmbracelet/x` monorepo; only `ansi/` is ported). The
    refresh checklist and exact diff are in
    `plans/upstream-refresh-cb897cb.md`.
  - `spec/array_validation_spec.cr` anchors the Go source path to `__DIR__`. It
    used to say `../x/ansi/color.go`, which resolves outside the repo whenever
    the suite runs from the root, so both constant-array validations silently
    skipped; the hex parser then also rejected Go's `0x`-prefixed literals. Both
    are fixed, and the spec now compares 256 `ANSI_HEX` and 256 `ANSI256_TO_16`
    entries against `color.go` on every `make test`.
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
  - The lookahead fix was verified against the vendored Go source three ways:
    7 571 curated/random cases (Indic conjuncts, ZWJ families, tag flags, Hangul,
    RI pairs, escapes, long clusters) and 3 263 invalid-UTF-8 cases produce
    byte-identical `string_width`, `string_width_wc`, and cluster lists before
    and after the change; against Go's `StringWidth`/`FirstGraphemeCluster` walk
    only the 2 `Prepend`-run cases above differ. Go is linear here already
    (its `uax29` iterator is lazy, and printable ASCII takes the iterator's hot
    path), so the Crystal-side regression spec is a cost bound rather than an
    output golden.
  - Segmentation cost budget: `string_width` on 8 000 ASCII bytes is ~1 ms,
    and 3 000 mixed clusters take ~45 ms in a debug build. The specs bound those
    at 100 ms and 400 ms.
  - Sixel decoder differential fuzzing (200 randomized images) matches Go for
    raster bounds, out-of-bounds pixels, palette definitions, RLE, CR/LF, and
    RLE token consumption.
  - The checkout volume can create AppleDouble `._*` sidecars; run
    `make sidecars` or `make clean` if git or spec discovery misbehaves.
  - The ledger and `docs/plan/audit.md` describe the same coverage from two
    directions: the TSV is machine-checked but uncurated, the markdown is
    hand-verified but not validated by tooling. Until the ledger is curated, a
    `make parity` pass means "no drift against the pinned checkout", not "every
    declaration is ported".
- **Last feature commit:** `chore: move the upstream checkout to vendor/x` (follows
  `chore: adopt the parity inventory tooling` and the linear-time segmentation
  port).
- **Gates:** `make build`, `make format`, `make lint`, `make test` (523
  examples), and `make parity` (1 314 declarations, 269 tests) pass.

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
- [x] Segmentation cost: the first cluster comes from a doubling lookahead
      window and printable ASCII never reaches the segmenter, so `string_width`,
      `each_grapheme_cluster`, `truncate`, `wrap`, and the input decoders are
      linear (`ansi.1`)
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
- [x] Adopt the `cross-language-crystal-parity` tooling: inventory manifests,
      `make parity` / `parity-refresh` / `parity-reconcile`, and the
      AGENTS.md pointer
- [x] Move the upstream checkout to the repository-standard `vendor/x`
      submodule path and make every doc, the Makefile, and the specs point at
      `vendor/x/ansi`
- [ ] Curate `plans/inventory/go_port_inventory.tsv` from `docs/plan/audit.md`
      (rename rules for `String()` → `to_s`, `SetFoo` → `foo=` / `set_foo`,
      ALL-CAPS helpers; exclude upstream test helpers from the source scope) so
      the ledger carries real statuses instead of the bootstrap `missing`

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
