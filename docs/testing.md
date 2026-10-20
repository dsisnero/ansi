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
  for example `x/ansi/programstatus_test.go` → `spec/program_status_spec.cr`.
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

## Fixtures

Large fixtures may live under `spec/`; scratch data must stay under `./temp`.
Do not commit generated output or AppleDouble sidecars.

## Baseline

Run the full suite before starting work. The expected result at the current
pin is recorded in `plans/parity.md`; update that record when the count or
status changes.
