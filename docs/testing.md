# Testing

## Commands

```bash
make test                    # full suite
crystal spec spec/program_status_spec.cr
crystal spec spec/program_status_spec.cr:42
```

`make test` is the gate that must pass before every commit.

## Porting upstream tests

- Put the Crystal spec in the file that mirrors the upstream `*_test.go` file,
  for example `vendor/x/ansi/programstatus_test.go` →
  `spec/program_status_spec.cr`.
- Port the test data exactly: same inputs, expected sequences, limits, and
  error paths. Crystal loops or `it` blocks may replace Go table tests without
  changing coverage.
- Keep edge cases such as UTF-8 truncation, invalid IDs, clamped progress, and
  control-character sanitization.
- Never weaken an assertion to make the suite green. If behavior is blocked,
  use `pending` with a reason and record it in `plans/parity.md`.

## Characterization specs

When Go tests cannot be ported directly (for example because they use Go-only
test helpers), write a characterization spec that locks the observable
behavior and note the divergence in the plan.

## Differential checks

Width and segmentation are verified against the vendored Go source rather than
only against hand-written expectations. When touching `src/gcb.cr`,
`src/grapheme.cr`, `src/width.cr`, `src/truncate.cr`, `src/wrap.cr`, or
`src/parser_decode.cr`, compare a corpus against a small Go program built on
`vendor/x/ansi` and expect byte-identical `string_width`, `string_width_wc`,
cluster lists, and decode results. The corpora recorded in
`plans/parity.md` are: ~10.5k valid cases (Indic conjuncts, ZWJ families, tag
flags, Hangul, Prepend runs, RI pairs, escapes, long CJK runs), the `Prepend`
matrix, invalid UTF-8 (truncated sequences, stray continuations), and the
`DecodeSequence` parameter-limit matrix.

Cost specs (`spec/grapheme_cluster_spec.cr`, "segmentation cost") bound linear
behavior on 99 KB inputs; they take the fastest of a few samples because a
loaded machine can otherwise drift past the bound.

## Fixtures

Large fixtures may live under `spec/`; scratch data must stay under `./temp`.
Do not commit generated output or AppleDouble sidecars.

## Baseline

Run the full suite before starting work. The expected result at the current
pin is recorded in `plans/parity.md`; update that record when the count or
status changes.
