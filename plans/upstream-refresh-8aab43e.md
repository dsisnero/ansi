# Upstream Refresh — ansi `cb897cb` → `8aab43e`

Vendor refresh plan for the Crystal port, from the previous pin to the latest
upstream `main`. The submodule has been moved to `8aab43e`; this plan covers
porting the `ansi/` changes to Crystal and is linked from
[plans/parity.md](parity.md).

## Where we are

- **Port state at refresh start:** `4840b70` (`fix(width): segment grapheme
  clusters in bounded chunks`), tree green at 525 examples.
- **Previous vendor pin:** `cb897cb` (2026-10-18, `chore(powernap): update lsp
  configs`), tag `ansi/v0.11.9`.
- **New vendor pin:** `8aab43e` (2026-11-22, `chore(powernap): update lsp
  configs`), the tip of upstream `main`. Tag `ansi/v0.11.10` is `ee8f503`, one
  commit below the tip and identical for `ansi/`.
- **Upstream range reviewed:** `git -C vendor/x diff cb897cb 8aab43e -- ansi`.
- **Not in scope:** the other 7 commits in the range (`powernap` config churn,
  the `exp/charmtone` deprecation and tag, and a `golang.org/x/sys` bump in
  `term/`).

## Changes found

One commit touches `ansi/` in the range:

```text
c957a7d fix(ansi): bound DecodeSequence parameter collection (#1012)
```

Files changed under `ansi/`:

```text
M ansi/parser.go
M ansi/parser_decode.go
M ansi/parser_decode_test.go
```

The change is a bounds hardening, not a new feature: once a sequence carries
more parameters than the parser was sized for (`SetParamsSize`, default
`parser.MaxParamsSize` = 32), `DecodeSequence` wrote `p.params[p.paramsLen]`
past the end of the slice. Upstream fixed it three ways:

1. `decodeSequence` guards the digit write, the `:` `HasMoreFlag` write, and the
   `;`/`:` parameter advance with `p.paramsLen < len(p.params)`.
2. The dispatch "increment the last parameter" condition becomes
   `p.paramsLen < len(p.params)` (was `len(p.params)-1`), so `paramsLen`
   saturates at capacity instead of stopping one short.
3. `Parser.performAction`'s dispatch increment gets the same change, so the
   streaming parser and `DecodeSequence` agree on the parameter count.

Relevant upstream tests, ported here ahead of the implementation:

- `TestDecodeSequenceParameterLimit` — matrix over sizes `{0, 1, 2, Max}`,
  counts `{1, size, size+1, size+3}`, separators `;`/`:`, prefixes
  CSI/8-bit-CSI/DCS/8-bit-DCS: the decode must consume the whole sequence,
  saturate `paramsLen` at `min(size, count)`, keep values `1..count`, set
  `HasMoreFlag` on every `:`-separated parameter but the last, and reset for
  the following printable rune.
- `TestParserMatchesDecodeSequenceAtParameterLimit` — `Parser#advance` and
  `DecodeSequence` keep the same `paramsLen` at `Max-1`, `Max`, `Max+1`.
- `TestDecodeSequenceParameterOverflowStreaming` — splitting an overflowing
  sequence at every byte boundary keeps `paramsLen == MaxParamsSize`, every
  parameter equal to `1`, and consumes both chunks fully (both `WcWidth` and
  `GraphemeWidth` entry points).
- Fuzz seeds gain two overflowing CSI/DCS inputs; the fuzz target now passes a
  `Parser` instead of `nil` so the parameter path is exercised.

Our port had the same defect: `src/parser_decode.cr` indexed
`p.params[p.params_len]` unguarded and advanced `params_len` past capacity, and
both `DecodeSequence` and `Parser#advance` used `size - 1` for the saturation
test.

## Checklist

- [x] Move the submodule to `8aab43e` and parent-pin it
- [x] Port the three parameter-limit tests
      (`spec/parser_decode_spec.cr`, `Ansi.decode_sequence parameter limit`);
      confirmed red on the old code (`IndexError` at
      `src/parser_decode.cr:124`, `params_len` 31 where 32 was expected)
- [x] Guard parameter writes and saturate `params_len` in `src/parser_decode.cr`
- [x] Apply the dispatch-increment change in `src/parser.cr`
- [x] Refresh the parity manifests (`make parity-refresh`): 1 314 API items
      unchanged, tests 269 → 275 (the three new tests appear as both `test` and
      `function` kinds)
- [x] Update `plans/parity.md` (pin, gates, status) and this checklist
- [x] Gates: `make build`, `make format`, `make lint`, `make test` (528
      examples), `make parity` (1 314 declarations, 1 314 API items, 275 tests)

## Notes

- `SetParamsSize(0)` is a real case in the upstream test matrix, so every guard
  has to tolerate an empty parameter array as well as a full one.
- `Parser#advance` already returned early when `@params_len >= @params.size`
  (`src/parser.cr`), so the streaming path only needed the saturation change;
  the decode path had no such guard.
- Upstream also added two overflowing fuzz seeds (`\e[` and `\eP` with
  `MaxParamsSize` parameters) and made the fuzz target pass a `Parser` instead of
  `nil`. This port has no fuzz target, so the equivalent coverage comes from the
  split-at-every-offset streaming spec above, which exercises the same paths.
- The refresh also confirms the pin covers `ansi/v0.11.10` (`ee8f503`): the tag
  is one `powernap` chore below `8aab43e` and `ansi/` is identical between them.
