# PR Workflow

1. Create a branch from `main` for one feature-sized change.
2. Implement the port and its specs; keep unrelated refactors out of the
   branch.
3. Update `docs/plan/audit.md` and refresh the **Where we are** block in
   `plans/parity.md`.
4. Run the gates:

   ```bash
   make format
   make lint
   make test
   ```

5. Commit atomically:

   ```text
   port: <feature>

   - <what changed>
   - <tests added>
   - divergences: <none or detail>

   Upstream: charmbracelet/x <tag-or-commit>
   Gates: make lint, make test
   ```

6. Push the branch and open a PR that links the upstream file/test being
   ported and calls out any intentional divergence.
7. Address review findings with additional commits; do not rewrite published
   history unless the change is yours alone and still in review.

## Review checklist

- Behavior matches the Go implementation, including error and empty-string
  cases.
- Specs cover the upstream test cases without weakened assertions.
- `make format`, `make lint`, and `make test` pass.
- `plans/parity.md` and `docs/plan/audit.md` reflect the new state.
- No vendored files under `x/` were modified and no scratch files were
  committed.
