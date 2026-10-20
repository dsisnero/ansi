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
- `spec/*_spec.cr` — Crystal specs, generally mirroring the corresponding
  upstream `*_test.go` file.

## Upstream reference

The upstream source is vendored as the `x` git submodule and lives at
`x/ansi`. Treat it as read-only. The pinned commit is recorded in
`plans/parity.md`; newer tagged files are fetched only when porting a specific
feature.

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

`plans/parity.md` is the feature roadmap and resume state. `docs/plan/audit.md`
is the per-symbol coverage ledger that maps upstream declarations to Crystal
files and methods.
