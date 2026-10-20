# Parity Plan — ansi

Curated feature roadmap for the Crystal port. Keep this file human-curated and
refresh the **Where we are** block after every feature. Per-symbol coverage
lives in [`docs/plan/audit.md`](../docs/plan/audit.md).

## Where we are

- **Current focus:** maintain API and spec parity with the vendored
  `charmbracelet/x/ansi` checkout at commit `eeb2896`, and port newer upstream
  features when requested.
- **Next up:**
  1. Fix HSL conversion accuracy in Sixel so pure colors match Go.
  2. Add the missing Sixel palette quantization tests.
  3. Port the remaining color tests and extend `Color` functionality.
  4. Implement the remaining Sixel decoder behavior and `FullImage` tests.
  5. Reconcile the test-only unchecked entries in the audit; confirm
     `sixel/palette_sort.go`'s xorshift remains intentionally unnecessary.
- **Status by area:**
  - Core ANSI sequences (colors, styles, cursor, modes, mouse, clipboard,
    notifications, hyperlinks, terminal reports): ported.
  - Parser, transitions, decode helpers, handlers: ported.
  - Kitty and iTerm2 graphics: ported.
  - Sixel: in progress — decoder and palette quantization have gaps.
  - Program Status Protocol (OSC 7501): ported from `ansi/v0.11.9`.
- **Scoping notes / gotchas:**
  - The vendored submodule is pinned at `eeb2896`; newer tagged files are not
    present in that checkout. Fetch the specific tag when porting a newer
    feature and record it here (see `docs/development.md`).
  - `sixel/palette_test.go` and `parser_test.go` contain Go test-only helper
    structs that are not API surface; the audit marks them unchecked.
  - The checkout volume can create AppleDouble `._*` sidecars; run
    `make sidecars` or `make clean` if git or spec discovery misbehaves.
- **Last commit:** `e5a6c9b Port OSC 7501 program status encoding from Go`
- **Gates:** `make lint` pass; `make test` pass (338 examples).

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
- [ ] Sixel palette quantization tests
- [ ] Sixel HSL conversion accuracy

## Phase 3 — Newer upstream features

- [x] Program Status Protocol (OSC 7501) from `ansi/v0.11.9`
- [ ] Re-audit `x/ansi` against a newer upstream tag and add missing behavior

## Intentional divergences

- Sixel palette sorting uses a deterministic Crystal sort instead of the Go
  xorshift priority queue; the resulting color selection is intended to match.
- `ProgramState` and `ProgramStatusKind` are Crystal value structs rather than
  Go named-string types, preserving invalid-value handling while using Crystal
  idioms.
- The Go-compatible `set_program_status` writer delegates to the idiomatic
  `program_status=` writer.
