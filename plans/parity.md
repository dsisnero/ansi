# Parity Plan — ansi

Curated feature roadmap for the Crystal port. Keep this file human-curated and
refresh the **Where we are** block after every feature. Per-symbol coverage
lives in [`docs/plan/audit.md`](../docs/plan/audit.md).

Each checkbox is one shippable, feature-sized commit. A feature may span
several files and upstream tests; batch related behavior, tests, audit rows,
and plan updates into that commit. Do not split one feature into per-edge-case
micro-commits.

## Where we are

- **Current focus:** maintenance. Every upstream file in the pinned checkout has
  a Crystal counterpart and the hand-verified audit ledger has no unchecked rows.
  The port is pinned to upstream `8aab43e` (`ansi/v0.11.10`), whose only `ansi/`
  change since `cb897cb` was a bounds fix in `DecodeSequence`
  (`plans/upstream-refresh-8aab43e.md`). Grapheme segmentation is now the vendored
  UAX #29 splitter itself — `src/gcb.cr` carries uax29's property ranges and
  `src/grapheme.cr` ports its rule ladder — replacing the `textseg` shard, which
  is no longer a dependency. That removed the last divergence: 10 503 valid, 504
  `Prepend`, 3 266 invalid-UTF-8 and 732 `DecodeSequence` differential cases all
  match the vendored Go source exactly. The machine-checked ledger was
  bootstrapped; curating it is the open work.
- **Next up:**
  1. Finish the parity ledger: 1 247 of 1 314 declarations are `ported` with a
     verified ref, 3 are `skipped` (upstream entry points) and 3 are
     `intentional_divergence` (Go generic constraints). The remaining 61 are
     `missing` with a "needs a manual mapping" note — mostly sixel internals the
     port restructured (`sixelBuilder`, `sixelPalette`, `cubePriorityQueue`,
     `xorshift`, the pdqsort helpers), Go-only bits folded into locals
     (`bitAdd`/`bitsMask`), and helpers that exist under another name (`nbsp`,
     `isNaN`, `shift`, `rgbToHex`, `isZeroWidthHigh`, `URxvtExt`,
     `backgroundColorString`). Close them by inspecting each against
     `vendor/x/ansi`. Conventions live in `plans/parity_rules.yml`; the ledger
     was derived with them plus a name check, and every `ported` row's symbol was
     verified against its ref file.
  2. Re-audit `vendor/x/ansi` against upstream `main` and port any new behavior
     as one coherent feature, following the pattern of
     `plans/upstream-refresh-8aab43e.md`. A no-op while `main` remains
     `8aab43e`; check `git -C vendor/x log --oneline 8aab43e..origin/main -- ansi`
     first.
  3. Extend differential characterization coverage as upstream dependency
     tables advance: the vendored `src/gcb.cr` and the displaywidth/runewidth
     tables are now the only sources of Unicode truth, so refresh them together
     when upstream moves.
- **Status by area:**
  - Core ANSI sequences and parser: ported.
  - Width measurement: ported, and linear in the input. GraphemeWidth uses
    vendored displaywidth v0.11.0 tables and WcWidth uses vendored go-runewidth
    v0.0.27 tables. Grapheme cluster segmentation is uax29's own: `src/gcb.cr`
    (property ranges from Unicode 17.0.0, including the InCB columns) plus
    `src/grapheme.cr` (the GB3–GB13 rule ladder and its four state bits), and
    `Ansi.each_grapheme_cluster` exposes it to consumers. Printable ASCII never
    reaches the splitter.
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
    138 methods, 33 types, 20 classes, 6 interfaces; 1 247 ported, 61 missing,
    3 skipped, 3 intentional divergences) plus generated `go_source_parity.tsv` /
    `go_test_parity.tsv` snapshots with their `.metadata.json`.
    `plans/parity_rules.yml` records the naming conventions (Go `String()` →
    `to_s`, `SetFoo` → `foo=` / `set_foo`, digit splitting, and the 54 upstream
    `is an alias for` comments). `make parity` re-validates all three against
    `vendor/x/ansi` with the tree-sitter backend; `make parity-refresh` is for
    an upstream bump only; `make parity-reconcile` writes the disposable bundle
    under `plans/generated/` (gitignored) and is a cross-check, not the ledger's
    source.
- **Scoping notes / gotchas:**
  - The vendored submodule is pinned at `8aab43e` (2026-11-22, tag
    `ansi/v0.11.10`) and lives at `vendor/x` (the `charmbracelet/x` monorepo;
    only `ansi/` is ported). The current refresh checklist and exact diff are in
    `plans/upstream-refresh-8aab43e.md`; `plans/upstream-refresh-cb897cb.md` is
    the previous refresh, kept for history.
  - `spec/array_validation_spec.cr` anchors the Go source path to `__DIR__`. It
    used to say `../x/ansi/color.go`, which resolves outside the repo whenever
    the suite runs from the root, so both constant-array validations silently
    skipped; the hex parser then also rejected Go's `0x`-prefixed literals. Both
    are fixed, and the spec now compares 256 `ANSI_HEX` and 256 `ANSI256_TO_16`
    entries against `color.go` on every `make test`.
  - The latest `ansi` tag is `ansi/v0.11.10` (`ee8f503`), one `powernap` chore
    below the pin; `ansi/` is identical between them. The pin is the tip of
    upstream `main`, so a re-audit is now a no-op until `main` moves again.
  - Width classification uses vendored displaywidth v0.11.0 tables for
    GraphemeWidth and go-runewidth v0.0.27 tables for WcWidth. Single-codepoint
    differential vs Go over U+0000..U+1FFFF is 0 grapheme mismatches and 0
    wcwidth mismatches out of 129,024.
  - The Indic_Conjunct_Break columns of `src/gcb.cr` come from the same uax29
    v2.7.0 tables. Segmentation plus cluster widths were compared against a Go
    `FirstGraphemeCluster` loop: 3,450 random sequences, 310 hand-picked cases,
    and every codepoint of the ten Indic blocks plus Myanmar and Khmer after a
    consonant + Linker, with 0 mismatches for WcWidth and GraphemeWidth.
  - Sixel HLS uses a native port of Go's `colorful.Hsl` plus Go's 16-bit
    rounding, not the Crystal `colorful` shard.
  - `Convert256` uses `Math.fma` to reproduce Go's fused channel arithmetic at
    cube boundaries.
  - Grapheme segmentation is the vendored UAX #29 splitter: `src/gcb.cr` holds
    the code point → property ranges decoded from
    `github.com/clipperhouse/uax29/v2@v2.7.0`'s generated tables (Unicode 17.0.0
    GraphemeBreakProperty plus the emoji and Indic_Conjunct_Break columns, 1 631
    ranges), and `src/grapheme.cr` ports uax29's rule ladder (GB3–GB13) with its
    four state bits (previous two properties, regional indicator run, InCB). The
    `textseg` shard was the last divergence and is no longer a dependency: its
    state machine is single-slot, so a Prepend, a control or an illegal byte
    reset whatever it was tracking. Differential against Go at the pin, all
    byte-identical:
    - 10 503 valid cases (Indic conjuncts, ZWJ families, tag flags, Hangul,
      Prepend runs, RI pairs, escapes, 99 KB CJK runs, random code points);
    - 504 `Prepend` cases (every Prepend code point × followers, runs, with
      Extend/ZWJ/SpacingMark, Prepend + RI, Prepend + conjunct);
    - 3 266 invalid-UTF-8 inputs, including truncated sequences, stray
      continuations and every byte class after printable ASCII;
    - 732 `DecodeSequence` cases (parameter counts to 64, both separators,
      CSI/DCS and 8-bit prefixes, split at every offset).
  - Malformed input is segmented the way uax29 does it: an illegal sequence
    advances by the bytes the decoder could trust (1 for a stray continuation, 2
    for a bad third byte, and so on), and an encoding cut short by the end of the
    input takes the rest of the buffer as the final cluster. `bytes_to_string`
    keeps those raw bytes in the yielded `String`, so a cluster's length and its
    measured width stay consistent.
  - `GCB.property` starts its range search from the 256-code-point page the code
    point falls in (`PAGE_RANGES`): most pages hold one range, the worst 38.
    That took the lookup from ~233 ns to ~115 ns and the 99 KB walk from ~621 ns
    to ~452 ns per code point.
  - Segmentation cost budget: `string_width` on 8 000 ASCII bytes is ~0.8 ms,
    and 3 000 mixed clusters take ~45 ms in a debug build. The specs bound those
    at 100 ms and 400 ms. On a 99 KB katakana string (`"あ" * 33_000`) the walks
    are ~17 ms (`string_width`), ~43 ms (`each_grapheme_cluster`), ~33 ms
    (`truncate`) and ~36 ms (`cut`); the cost specs bound the walk and the
    measure/slice mix at 300 ms per operation. A single-code-point
    `Grapheme.cluster_end` costs ~166 ns, against the ~10 µs fixed cost the
    `textseg` shard paid per call, and the per-code-point cost is flat from 10 000
    to 264 000 code points. Go's `StringWidth` does the same 99 KB in ~1.8 ms;
    the remaining gap is Crystal-side constant factors (table access, bounds
    checks, displaywidth lookups), not complexity.
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
- **Last feature commit:** `port: bound DecodeSequence parameters` on top of
  `chore: move the upstream checkout to vendor/x`; it follows the linear-time
  segmentation port and the parity-tooling adoption.
- **Gates:** `make build`, `make format`, `make lint`, `make test` (528
  examples), and `make parity` (1 314 declarations, 1 314 API items, 275 tests)
  pass.

## Phase 1 — Core ANSI and parser

- [x] Sequence builders: colors, palette, titles, cursor, modes, mouse,
      clipboard, notifications, hyperlinks, CWD, focus, paste, passthrough, and
      terminal control helpers
- [x] Parser: state machine, transitions, handler API, decode helpers, and the
      supporting Go test port
- [x] Parser invalid UTF-8: `Parser#rune` decodes the collected bytes with
      U+FFFD substitution like Go's `utf8.DecodeRune`, with characterization
      specs verified against the vendored parser
- [x] Parser parameter bounds: `DecodeSequence` guards parameter writes and
      saturates the count at the configured capacity, and the streaming parser
      agrees with it (`plans/upstream-refresh-8aab43e.md`)

## Phase 2 — Width and colors

- [x] Width model: Wcwidth per codepoint, GraphemeWidth presentation/RI/tag/
      zero-width handling, Unicode 17 tables, Indic GB9c joins, and differential
      coverage against Go
- [x] Grapheme segmentation API: `Ansi.each_grapheme_cluster` yields clusters
      and widths from the same parser loop as `string_width`, backed by
      vendored Indic_Conjunct_Break tables so GB9c boundaries match Go
- [x] Segmentation cost: the splitter reads one code point at a time and
      printable ASCII never reaches it, so `string_width`,
      `each_grapheme_cluster`, `truncate`, `wrap`, and the input decoders are
      linear (`ansi.1`)
- [x] Vendored UAX #29 splitter: `src/gcb.cr` (uax29 v2.7.0 property ranges,
      Unicode 17.0.0) and `src/grapheme.cr` (GB3–GB13 rule ladder), replacing the
      `textseg` shard; 0 diffs against Go over 10 503 valid, 504 `Prepend`,
      3 266 invalid-UTF-8 and 732 `DecodeSequence` cases
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
- [x] Re-audit upstream `main` and port any new behavior as one feature:
      `cb897cb` → `8aab43e` was a single `ansi/` fix (bounded `DecodeSequence`
      parameters), ported in `plans/upstream-refresh-8aab43e.md`
- [x] Port/vendor `clipperhouse/displaywidth` tables for exact width parity
- [x] Vendor go-runewidth tables for exact WcWidth parity
- [x] CI hardening: supported-Crystal-version matrix and dependency caching
- [x] Adopt the `cross-language-crystal-parity` tooling: inventory manifests,
      `make parity` / `parity-refresh` / `parity-reconcile`, and the
      AGENTS.md pointer
- [x] Move the upstream checkout to the repository-standard `vendor/x`
      submodule path and make every doc, the Makefile, and the specs point at
      `vendor/x/ansi`
- [x] Curate `plans/inventory/go_port_inventory.tsv`: 1 247 of 1 314 declarations
      are `ported` with a ref verified against the source, 3 are `skipped`, 3 are
      `intentional_divergence`, and the naming conventions live in
      `plans/parity_rules.yml`. The remaining 61 rows are the first "Next up"
      item.
- [ ] **Later:** extract the grapheme splitter (`src/gcb.cr` +
      `src/grapheme.cr`, ~2 450 lines, no ANSI dependencies) into its own shard.
      Do it when a second consumer wants segmentation without ANSI, or when the
      richer API is needed — not before: today `ansi` is the only consumer and
      `ultraviolet` reaches it through `ansi`, so a split would add a dependency
      edge and a second table-update stream for no gain. Extraction shape:
      - move `src/gcb.cr`, `src/grapheme.cr`, and their specs; name the module
        `Graphemes`/`UAX29` rather than `Ansi::Grapheme`;
      - expose `cluster_end(bytes, offset, incb:)` and add the convenience layer
        `textseg` offers today — eager `clusters`, `each_cluster`, and per-cluster
        `codepoints`/`positions`/`str` (the extraction is not a drop-in
        replacement without it);
      - check in the table generator (uax29 v2.x trie or UCD files) and pin the
        Unicode version in the shard's docs;
      - keep `Ansi.each_grapheme_cluster` (including the `incb:` flag) as a thin
        delegating wrapper so consumers do not change, and keep the ANSI parser
        walk and the displaywidth measurement in `ansi`.
      Rationale on record: `textseg` 0.1.3 is Unicode 12.0.0, has no GB9c, and
      rebuilds a char→byte index per call, so it is quadratic (20 KB of katakana:
      183 ms vs 2 ms here, 99 KB: ~5 s vs ~16 ms) and its single-slot state
      machine mis-segments Prepend runs, Hangul and RI parity after a Prepend or
      control. The vendored splitter matches Go's `uax29` on 14 272 differential
      cases and reproduces `textseg`'s GB9c-free split with `incb: false`, so it
      strictly covers what the shard does behaviourally.

## Intentional divergences

- `ProgramState` and `ProgramStatusKind` are Crystal value structs rather than
  Go named-string types, preserving invalid-value handling while using Crystal
  idioms.
- The Go-compatible `set_program_status` writer delegates to the idiomatic
  `program_status=` writer.
- `GraphemeWidth` segments with the vendored UAX #29 splitter (`src/gcb.cr`
  properties from uax29 v2.7.0, Unicode 17.0.0, and the rule ladder in
  `src/grapheme.cr`); width classification comes from the vendored displaywidth
  tables. `WcWidth` follows Go's per-codepoint model and skips segmentation.
- `Ansi.each_grapheme_cluster` has no upstream counterpart: Go exposes
  `FirstGraphemeCluster`, a raw one-cluster primitive that leaves ANSI parsing
  to the caller. The Crystal helper walks the whole string with the same parser
  loop as `string_width`, skips escape sequences, and yields each cluster with
  its width so segmentation and measurement cannot drift apart.
- `Ansi.each_grapheme_cluster` and `Ansi::Grapheme.cluster_end` accept
  `incb:` (default `true`). `incb: false` reproduces `github.com/rivo/uniseg`,
  which Go's terminal input decoders use: without GB9c a virama ends its
  segment, so `"स्ते"` is `"स्"` + `"ते"` and a decoder can emit one key per
  segment. Measurement keeps GB9c (`string_width_wc` is 2 cells for the joined
  cluster). The mode exists so a consumer can segment for parsing and for width
  from one implementation instead of pulling in a second segmenter shard.
