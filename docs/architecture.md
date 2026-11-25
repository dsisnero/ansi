# Architecture

`ansi` is a Crystal port of the Go module `charmbracelet/x/ansi`. It generates
ANSI escape sequences and parses terminal input.

## Source layout

- `src/ansi.cr` — entrypoint; requires every source file and holds sequence
  builders that do not have a dedicated file.
- `src/*.cr` — one file per upstream Go file where practical: colors, styles,
  cursor control, modes, mouse/keyboard protocols, clipboard, notifications,
  hyperlinks, images (Kitty, iTerm2, Sixel), and terminal reports.
- `src/parser.cr`, `src/parser_*.cr` — terminal sequence state machine,
  transitions, decode helpers, and handler interfaces.
- `src/parser_transition.cr` — parser action and transition tables.
- `src/width.cr`, `src/wcwidth.cr`, `src/displaywidth.cr` — width measurement:
  per-cluster `GraphemeWidth`, per-code-point `WcWidth`, and the vendored
  Unicode tables each uses.
- `src/gcb.cr`, `src/grapheme.cr` — grapheme cluster segmentation: the Unicode
  property ranges and the UAX #29 rule ladder, both ported from the uax29
  release the Go source depends on.
- `spec/*_spec.cr` — Crystal specs, generally mirroring the corresponding
  upstream `*_test.go` file.

## Upstream reference

The upstream source is vendored as the `vendor/x` git submodule and lives at
`vendor/x/ansi`. Treat it as read-only. The pinned commit is recorded in
`plans/parity.md`; newer tagged files are fetched only when porting a specific
feature.

## Segmentation and width

Grapheme clusters and cell widths are the two places where behavior depends on
Unicode data, so both use tables vendored from the Go dependencies instead of a
Crystal shard:

- `src/gcb.cr` holds the Unicode 17.0.0 grapheme break properties decoded from
  `github.com/clipperhouse/uax29/v2`'s generated trie (including the
  `Extended_Pictographic` and `Indic_Conjunct_Break` columns).
- `src/grapheme.cr` applies uax29's rule ladder (GB3–GB13) with the same four
  state bits, so a boundary is the one `FirstGraphemeCluster` finds.
- `src/displaywidth.cr` and `src/wcwidth.cr` hold the width tables from
  `displaywidth` and `go-runewidth` used by `GraphemeWidth` and `WcWidth`.

`incb:` selects the GB9c rule: on (the default) matches width measurement and the
Go source, off reproduces `github.com/rivo/uniseg`, which is what Go's terminal
input decoders see. The ANSI parser walk stays here; only segmentation is
generic.

## Design constraints

- Public behavior, escape sequences, validation rules, and edge cases must match
  Go. Crystal idioms are used for types, naming, and standard-library calls
  without changing behavior.
- Parsing and encoding are independent layers: sequence builders return
  strings, while parser types consume bytes and expose params, commands, data,
  and handler callbacks.
- Image and graphics codecs (Kitty, iTerm2, Sixel) are self-contained and may
  use Crystal shards for compression or color conversion; any behavioral
  divergence is recorded in `plans/parity.md`.

## Tracking

`plans/parity.md` is the feature roadmap and resume state. The machine-checked
coverage ledger is `plans/inventory/go_port_inventory.tsv`: one row per upstream
declaration with a status, a Crystal ref, and a note naming the Crystal symbol.
`docs/plan/audit.md` is the annotated, per-area view of the same coverage.
`CHANGELOG.md` records user-visible changes.
