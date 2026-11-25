# Changelog

All notable changes to this shard are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html); the version in
`shard.yml` is the source of truth. The library tracks
`github.com/charmbracelet/x/ansi`; the pinned upstream revision for every entry
is recorded in [plans/parity.md](plans/parity.md).

Entries are grouped under `Added`, `Changed`, `Fixed`, `Performance`, and
`Docs and tooling`. New work goes under `[Unreleased]` in the same commit that
changes the behavior.

## [Unreleased]

### Added

- `Ansi::Grapheme` / `Ansi::GCB`: a UAX #29 grapheme cluster splitter with the
  Unicode 17.0.0 property tables (grapheme break properties, emoji
  `Extended_Pictographic`, and the `Indic_Conjunct_Break` columns) vendored from
  `github.com/clipperhouse/uax29/v2` — the segmenter the pinned Go source uses.
- `Ansi::Grapheme.cluster_end(bytes, offset, incb = true)` exposes that splitter
  for callers that segment raw bytes, and
  `Ansi.each_grapheme_cluster(s, method = Method::WcWidth, incb = true, &)`
  accepts the same switch. `incb: false` reproduces the GB9c-free boundaries of
  `github.com/rivo/uniseg`, so a terminal input decoder can emit one key per
  virama-delimited segment without a second segmenter shard.
- `plans/parity_rules.yml` records the Go→Crystal naming conventions used to
  attribute declarations (`String()` → `to_s`, `SetFoo` → `foo=` / `set_foo`,
  digit splitting, and upstream's own `is an alias for` comments).
- A curated parity ledger with a ref for every declaration:
  `plans/inventory/go_port_inventory.tsv` (1 295 `ported`, 15
  `intentional_divergence`, 4 `skipped`, 0 `missing`) alongside the generated
  source/test manifests and their `.metadata.json`.
- `make parity`, `make parity-refresh`, and `make parity-reconcile` wire the
  installed `cross-language-crystal-parity` checks into the repository.

### Changed

- Grapheme segmentation is now the vendored UAX #29 splitter over Unicode 17
  tables; the `textseg` shard (Unicode 12, no GB9c) is no longer a dependency.
- `Ansi.each_grapheme_cluster` and the width/truncate/wrap walkers read one code
  point at a time from the caller's offset instead of segmenting a copy of the
  remaining string.
- `bytes_to_string` keeps invalid UTF-8 bytes when yielding a cluster, so a
  cluster's bytes and its measured width can no longer disagree.
- The upstream checkout moved from `x/` to the repository-standard
  `vendor/x` submodule path; every document, the Makefile, and the specs
  reference `vendor/x/ansi`.
- The repository is pinned to upstream `8aab43e` (tag `ansi/v0.11.10`).

### Fixed

- `Ansi::Parser#decode_sequence` no longer writes past the configured parameter
  capacity: parameter writes are bounds-checked and the count saturates at the
  capacity, matching `Parser#advance` (upstream `c957a7d`, "bound DecodeSequence
  parameter collection").
- Grapheme clusters that follow a control code point match Go again: regional
  indicator pairs stay paired, `Prepend` runs keep joining, and an `Extend` no
  longer joins a control (GB4/GB5 outrank the joining rules).
- A truncated multi-byte sequence no longer hangs the segmentation walk; the
  walk terminates and matches Go, which treats the rest of the buffer as the
  final cluster.
- `spec/array_validation_spec.cr` resolves the vendored `color.go` from the spec
  directory and parses Go's `0x`-prefixed literals, so the 256-entry
  `ANSI_HEX` and `ANSI256_TO_16` validations actually run instead of skipping.

### Performance

- Width measurement and grapheme iteration are linear in the input. On a debug
  build, 99 KB of katakana takes ~17 ms for `string_width` (previously ~4.8 s
  through the eager segmenter), ~43 ms for `each_grapheme_cluster`, ~33 ms for
  `truncate`, and 8 000 ASCII bytes take ~0.8 ms. A single-code-point cluster
  costs ~166 ns, against the ~10 µs fixed cost the previous segmenter paid per
  call.
- The grapheme property lookup is indexed by 256-code-point page, which cut the
  lookup from ~233 ns to ~115 ns and the 99 KB walk from ~621 ns to ~452 ns per
  code point.

### Docs and tooling

- Added this changelog, linked from the README and `AGENTS.md`; the definition
  of done now requires an `[Unreleased]` entry for user-visible changes.
- `plans/upstream-refresh-8aab43e.md` documents the `cb897cb` → `8aab43e`
  refresh (the only `ansi/` change was the `DecodeSequence` bounds fix);
  `plans/upstream-refresh-cb897cb.md` is marked superseded.
- `plans/parity.md` records the differential verification against the vendored
  Go source: 10 502 valid, 504 `Prepend`, 3 266 invalid-UTF-8, and 732
  `DecodeSequence` cases, all byte-identical.
- `docs/architecture.md` and `docs/development.md` describe the vendored Unicode
  tables, the decoder mode, and the `make parity` gate.

## [0.1.0]

Initial Crystal port of `github.com/charmbracelet/x/ansi` at upstream
`cb897cb`: sequence builders for colors, styles, cursor control, modes,
mouse/keyboard/clipboard protocols, notifications, hyperlinks, and terminal
reports; the full parser state machine with decode helpers and handler
callbacks; width measurement (`WcWidth` per code point and `GraphemeWidth` over
clusters) with vendored `displaywidth` and `go-runewidth` tables; truncation and
wrapping; Kitty, iTerm2, and Sixel image codecs; the OSC 7501 program status
protocol; and the parser's U+FFFD handling for invalid UTF-8.
