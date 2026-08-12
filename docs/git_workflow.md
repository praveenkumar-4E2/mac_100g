# Git Workflow

## Daily flow

```bash
git status --short
git switch -c <type>/<short-description>
# edit, format, compile, test
git diff --check
git diff --stat
git add <only-files-you-changed>
git commit -m "<type>: <clear change>"
```

Example branches: `rtl/fix-rx-byte-count`, `tb/add-crc-test`, and
`docs/update-interface-guide`.

## Commit rules

One commit should make one reviewable change. Do not mix behavior changes,
large formatting changes, generated artifacts, and unrelated documentation.

Good commit messages:

```text
rtl: preserve final byte count through RX pipeline
tb: add RX malformed-FCS test
docs: explain native MAC/RS packet markers
```

## Before review

1. Inspect `git diff`.
2. Do not stage WLFs, logs, work libraries, or results.
3. Run formatting, `make compile`, and relevant tests.
4. State commands and outcomes in the review.
5. Record unrun tests or limitations honestly.

Never discard unrelated changes in a shared worktree without approval.
