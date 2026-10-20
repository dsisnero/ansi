# Parity Plan — ansi

Curated feature roadmap for the Crystal port. Keep this file human-curated and
refresh the **Where we are** block after every feature. Per-symbol coverage
lives in [`docs/plan/audit.md`](../docs/plan/audit.md).

Each checkbox is one commit-sized feature. If an upstream change touches
several unrelated files or behaviors, split it into separate items. Do not
bundle a broad area (for example "all colors") into a single work unit.

## Where we are

- **Current focus:** maintenance. Every upstream file in the pinned checkout
  has a Crystal counterpart, and the audit ledger has no unchecked rows.
- **Next up:**
  1. Re-audit `x/ansi` against upstream `main` and refresh the vendor pin.
     This is expected to be a no-op while `main` remains `cb897cb`.
  2. Decide whether to vendor/port `clipperhouse/displaywidth` tables for
     exact width parity with Go's tables.
  3. Add a CI matrix covering the supported Crystal versions.
- **Status by area:**
  - Core ANSI sequences: ported.
  - Parser and decode helpers: ported.
  - Width measurement: ported with Unicode 17 tables plus targeted fallbacks.
  - Colors and conversions: ported.
  - Kitty and iTerm2 graphics: ported.
  - Sixel codecs and quantization: ported.
  - Program Status Protocol (OSC 7501): ported from `ansi/v0.11.9`.
  - Quality gates: build, format, lint, and test run locally and in CI.
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
- **Last commit:** `14928dd` (docs: split parity phases into feature-sized units)
- **Gates:** `make build`, `make format`, `make lint`, `make test` pass
  (460 examples).

## Phase 1 — Core ANSI sequences

- [x] Foreground, background, and cursor color setters and resets
- [x] Palette set and reset sequences
- [x] Icon name, window title, and DEC title aliases
- [x] Cursor movement, positioning, and cursor style helpers
- [x] ANSI and DEC mode helpers
- [x] Mouse X10, SGR, and URXVT encoders
- [x] Clipboard set, reset, and request sequences
- [x] OSC 9 and OSC 99 notifications
- [x] Working-directory reporting
- [x] OSC 8 hyperlinks
- [x] Focus tracking and bracketed paste
- [x] Passthrough, tmux passthrough, and inband resize
- [x] Keypad, charset, reset, screen, termcap, and window-operation helpers

## Phase 2 — Parser

- [x] Parser state machine and transition table
- [x] Parser params, command, data, and handler API
- [x] Decode sequence, command, and parameter helpers
- [x] Control, ESC, CSI, DCS, OSC, and APC sequence handling
- [x] Parser support helpers and dispatcher test coverage

## Phase 3 — Width and colors

- [x] Wcwidth per-codepoint measurement
- [x] Grapheme text-presentation, keycap, regional-indicator, and tag handling
- [x] Standalone zero-width mark handling
- [x] Unicode 17 wide-rune tables via `unicode_width`
- [x] `Convert256` cube-boundary parity
- [x] `Convert16` overloads for every palette color type
- [x] Transparent and semi-transparent color handling
- [x] Color conversion helpers (`to_hex`, `to_rgb`, `to_true_color`,
      `with_alpha`, `to_indexed`, `to_basic`)
- [x] `Color#hex` and `Color#to_s` rendering

## Phase 4 — Graphics codecs

- [x] Kitty graphics encoder and decoder
- [x] Kitty options and the `Quiet` rename with deprecated `Quite`
- [x] Kitty keyboard protocol
- [x] iTerm2 file and inline image support
- [x] Sixel HLS conversion accuracy
- [x] Sixel palette quantization and lookup tests
- [x] Sixel palette segment sort (pdqsort + xorshift)
- [x] Sixel cube priority queue
- [x] Sixel nil and zero-size encoder behavior
- [x] Sixel empty decoder input behavior
- [x] Sixel writer byte-count return values
- [x] Sixel `FromColor(nil)` behavior

## Phase 5 — Upstream refresh and maintenance

- [x] Program Status Protocol (OSC 7501) from `ansi/v0.11.9`
- [x] Wcwidth per codepoint from the `cb897cb` refresh
- [x] Kitty `Quiet` rename from the `cb897cb` refresh
- [x] Width dependency audit against the refreshed upstream `go.mod`
- [x] Build gate and GitHub Actions CI
- [ ] Re-audit upstream `main` and refresh the vendor pin (one feature per
      upstream bump; expected no-op while `main` is `cb897cb`)
- [ ] Vendor/port `clipperhouse/displaywidth` tables for exact width parity
      (only if exact Go table parity becomes a hard requirement)
- [ ] Add a CI matrix for the supported Crystal versions

## Intentional divergences

- `ProgramState` and `ProgramStatusKind` are Crystal value structs rather than
  Go named-string types, preserving invalid-value handling while using Crystal
  idioms.
- The Go-compatible `set_program_status` writer delegates to the idiomatic
  `program_status=` writer.
- `GraphemeWidth` carries a targeted UAX #29 GB9c merge for major Indic viramas
  and supplemental Unicode 17 width handling where Go's tables are older.
  `WcWidth` follows Go's per-codepoint model.
