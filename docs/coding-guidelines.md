# Coding Guidelines

## Crystal style

- Run `crystal tool format` before committing; `make format` checks without
  rewriting.
- Run `ameba`; `make lint` applies safe fixes and then verifies.
- Use `snake_case` for methods and variables, `CamelCase` for types and modules,
  and `UPPER_SNAKE_CASE` for constants that are truly constant.
- Prefer Crystal's standard library and avoid unnecessary `as` casts. Narrow
  types with `case`, overloads, or nil checks.
- Keep one source file per upstream Go file where practical and add the
  `require` to `src/ansi.cr`.

## Porting behavior

- Upstream `x/ansi` is authoritative. Do not "improve" escape sequences,
  validation, clamping, or ordering.
- Port the Go test table cases before changing implementation. Specs must
  assert concrete sequences and values, not just that a method runs.
- Do not weaken assertions or delete edge cases to make a spec pass. If a case
  is blocked, mark it `pending` with the reason and record it in
  `plans/parity.md`.
- Document public behavior with the sequence form or a link to the upstream
  protocol documentation.

## Naming and API shape

- Convert Go `FooBar` names to Crystal `foo_bar` methods and preserve constant
  names such as `Ansi::RequestProgramStatusSupport`.
- When a Go `SetFoo` method is part of the public contract, expose both the
  Crystal-idiomatic writer (`foo=`) and a `set_foo` compatibility method. The
  writer holds the implementation; `set_foo` delegates.
- Do not silence `Naming/AccessorMethodName`. Use `# ameba:disable` only for
  rules such as `Metrics/CyclomaticComplexity` where the port intentionally
  mirrors upstream control flow.

## Errors and return values

- Match Go's sentinel behavior: empty strings, invalid-value omission, or
  exceptions should mirror what the Go API does.
- Do not add Crystal-only exceptions or validation that upstream does not have.

## Divergences

Any intentional divergence (shard behavior, deterministic sorting, missing
upstream API) must be recorded in `plans/parity.md` and, when relevant, the
commit message.
