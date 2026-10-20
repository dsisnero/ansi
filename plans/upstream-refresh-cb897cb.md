# Upstream Refresh — ansi `eeb2896` → `cb897cb`

Vendor refresh plan for the Crystal port. The submodule was not at upstream
`main`: the previous pin was `eeb2896` (2026-02-09) and the latest upstream
`main` is `cb897cb` (2026-10-18). The submodule has been moved to `cb897cb`;
this plan covers porting the `ansi/` changes to Crystal.

## Where we are

- **Previous vendor pin:** `eeb2896` (`feat(exp/slice): Map function`).
- **Current vendor pin:** `cb897cb` (`chore(powernap): update lsp configs`).
- **Latest `ansi` tag:** `ansi/v0.11.9`.
- **Upstream range reviewed:** `git -C x diff eeb2896 cb897cb -- ansi`.
- **Already ported:** OSC 7501 Program Status (`09f7503`) landed in this port
  as commit `e5a6c9b`; no work expected beyond re-running its spec.
- **Not in scope:** upstream commits outside `ansi/` (powernap, editor, etc.).

## Changes found

15 commits touch `ansi/` in the range:

```text
09f7503 feat(ansi): OSC 7501 (#1004)
3e0d13d chore(deps): bump the all group across 1 directory with 2 updates (#941)
00c6608 fix(wcwidth): measure wcwidth per codepoint (#933)
c2cf573 chore(ansi): lint (#943)
3eef36e chore(deps): bump github.com/bits-and-blooms/bitset (#914)
c3ad58c chore(deps): bump github.com/bits-and-blooms/bitset (#889)
f47db51 chore(deps): bump github.com/mattn/go-runewidth (#883)
72ac425 fix(ansi): kitty Options.Quite -> Quiet (#849)
6921c75 fix(ansi): width: always use grapheme finder for width calculation
eecd65c chore(deps): bump github.com/mattn/go-runewidth (#834)
b898337 chore(deps): bump github.com/mattn/go-runewidth (#824)
c0e82bc chore(deps): bump github.com/lucasb-eyer/go-colorful (#817)
a790580 chore(deps): bump github.com/mattn/go-runewidth (#800)
61df8bc chore(ansi): add basic tests for Method.StringWidth
6897110 chore(deps): bump the all group in /ansi with 3 updates (#781)
```

Files changed under `ansi/`:

```text
M ansi/color.go
M ansi/go.mod
M ansi/go.sum
M ansi/kitty/options.go
M ansi/kitty/options_test.go
M ansi/kitty/writer.go
A ansi/method_test.go
M ansi/mouse.go
M ansi/parser/transition_table.go
M ansi/parser_decode.go
A ansi/programstatus.go
A ansi/programstatus_test.go
M ansi/sixel/encoder.go
M ansi/sixel/palette.go
M ansi/sixel/palette_sort.go
A ansi/wcwidth.go
A ansi/wcwidth_test.go
M ansi/width.go
M ansi/width_test.go
```

## Phase 1 — Wcwidth per codepoint (behavioral)

Upstream commits: `6921c75`, `00c6608`, `61df8bc`. This is the largest change
and the one most likely to affect existing output.

### Implementation

- [x] Add `src/wcwidth.cr` porting `x/ansi/wcwidth.go`:
  - zero-width categories `Mn`, `Me`, `Cf` (combining marks, enclosing marks,
    ZWJ, variation selectors, tag characters) using Crystal's Unicode tables;
  - `wc_rune_width(r)`: C0/C1 and DEL are 0, printable ASCII is 1, zero-width
    tables win over the width shard, everything else falls back to
    `UnicodeCharWidth.width`;
  - `wc_cluster_width(cluster)`: sum `wc_rune_width` over codepoints, for both
    `String` and `Bytes`.
- [x] Update `src/width.cr`:
  - For `Method::WcWidth`, decode one rune at a time in `string_width` and add
    `wc_rune_width`; do not run grapheme segmentation.
  - In `first_grapheme_cluster`, make the `WcWidth` branch use
    `wc_cluster_width`.
  - Keep the grapheme-aware behavior for `Method::GraphemeWidth`, refined to
    match the refreshed Go method tests.
  - Remove the WcWidth-only regional-indicator/emoji overrides.
- [x] Keep `src/parser_decode.cr` on the shared `first_grapheme_cluster` helper;
  no direct edit was needed after the cluster-width update.

### Tests

- [x] Add `spec/wcwidth_spec.cr` porting `ansi/wcwidth_test.go`:
  `TestWcClusterWidth`, `TestWcRuneWidth`, `TestWcRuneWidthEastAsian`, and a
  sampled equivalent of `TestIsZeroWidthHigh`.
- [x] Add `spec/method_spec.cr` porting `ansi/method_test.go`
  (`TestMethod_StringWidth`): WcWidth vs GraphemeWidth for ASCII, wide chars,
  emoji, ZWJ families, skin tones, combining marks, and VS16.
- [x] Update `spec/width_spec.cr` to the new expectations:
  - ZWJ family: `wcwidth` 2 → 6
  - emoji + `hello`: `wcwidth` 7 → 11
  - flag `🇸🇦`: `wcwidth` 1 → 2
  - add `(ﾟ` with `width` 1, `wcwidth` 2

### Acceptance

- Crystal output matches the Go table for every case above.
- `Ansi.string_width` (grapheme default) is unchanged for existing cases and
  now also matches the new upstream method tests.
- `make test` passes (405 examples).

Phase 1 is complete. `GraphemeWidth` needed two supporting refinements to keep
the new upstream tests green: a targeted UAX #29 GB9c merge for major Indic
viramas, and VS15/keycap/emoji handling that matches the refreshed
`displaywidth` results. The remaining dependency audit stays in Phase 3.

## Phase 2 — Kitty `Quiet` option rename (behavioral)

Upstream commit: `72ac425`. The Go API adds `Quiet`, deprecates the misspelled
`Quite`, and gives the deprecated field precedence when non-zero.

- [x] In `src/kitty.cr` `Options`, add `property quiet : UInt8` and keep
  `property quite : UInt8` as deprecated.
- [x] In `Options#options`, emit `q=` from `quiet`, overridden by `quite` only
  when `quite > 0`.
- [x] Apply the same precedence in `build_chunk_options` for continuation
  chunks.
- [x] `Options.from_text`/unmarshal: `q=` populates `quiet` only, leaving the
  deprecated `quite` at zero.
- [x] Port the new test table from `ansi/kitty/options_test.go` to
  `spec/kitty_options_spec.cr` (Quiet-only, Quite-only, Quite overrides Quiet,
  `Quite=0`, both zero) and update existing fixtures to use `quiet`.
- [x] Verify `spec/kitty_writer_spec.cr` still passes for chunked output and
  add a continuation-chunk precedence test.

Phase 2 is complete. The deprecated `quite` field still works and overrides
`quiet` when non-zero; `q=` unmarshalling populates `quiet` only.

## Phase 3 — Dependencies and width behavior

Upstream `ansi/go.mod` moves to:

```text
bits-and-blooms/bitset      1.24.6
clipperhouse/displaywidth   0.11.0
clipperhouse/uax29/v2       2.7.0
lucasb-eyer/go-colorful     1.4.1
mattn/go-runewidth          0.0.27
```

- [x] Audit Crystal equivalents: `uniwidth` (runewidth tables) and
  `uni_text_seg` (uax29 graphemes), plus `colorful`, at their pinned versions.
- [x] Check whether a newer `uniwidth`/`uni_text_seg` release is needed for the
  width cases added in Phase 1: both were already at their latest tags (0.1.3),
  so no shard bump was available.
- [x] Superseded during follow-up: width now vendors `displaywidth` v0.11.0 and
  `go-runewidth` v0.0.27 tables directly; `uniwidth`/`unicode_width` were
  removed, while `textseg` remains a direct dependency for grapheme splitting.
- [x] No direct port of `go.mod`/`go.sum`; only behavior-affecting differences
  matter.

Phase 3 is complete. Width classification is now vendored, and the Sixel HLS
path uses a native Go-compatible implementation instead of the Crystal
`colorful` shard.

## Phase 4 — Confirm no-op and already-ported files

- [x] `ansi/programstatus.go` and `ansi/programstatus_test.go`: already ported
  in `e5a6c9b`; `spec/program_status_spec.cr` passes against the refreshed
  source.
- [x] Lint-only changes: `ansi/color.go`, `ansi/mouse.go`,
  `ansi/parser/transition_table.go`, `ansi/sixel/encoder.go`,
  `ansi/sixel/palette.go`, `ansi/sixel/palette_sort.go`, and the remaining
  `//nolint` edits in `ansi/parser_decode.go` contain no Crystal behavior
  changes.

## Verification and signoff

```bash
git -C x diff eeb2896 cb897cb -- ansi
cd x/ansi && go test ./...
make format
make lint
make test
```

- [ ] Add a differential check for the width table (Crystal vs Go) and keep the
  script or its cases under `./temp` only.
- [ ] Update `docs/plan/audit.md` with `wcwidth` and any new `method` coverage.
- [ ] Refresh `plans/parity.md` **Where we are** after each phase and record
  the vendor pin.
- [ ] Commit one phase at a time:
  - `port: wcwidth per codepoint`
  - `port: kitty Quiet option`
  - `chore: audit width dependencies`
  - `docs: record upstream refresh cb897cb`

## Risks and notes

- `Method::WcWidth` intentionally no longer treats a ZWJ family as one glyph;
  it measures each codepoint. Do not "fix" the larger widths back to grapheme
  behavior.
- Grapheme width tests must keep their current expectations; only WcWidth
  changes.
- The submodule checkout is detached at the recorded pin. Do not commit files
  under `x/`; only the parent submodule pointer changes.
- AppleDouble sidecars can reappear after git operations; run
  `make sidecars` before gates.
