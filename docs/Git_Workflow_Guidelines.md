# Git Workflow Guidelines — 100G Ethernet MAC UVM VIP Project

**Purpose:** This document defines how the team creates branches, commits code, opens pull requests, reviews changes, and releases the VIP using Git. It is written so that a fresh graduate with zero prior Git experience can follow it step-by-step, while giving experienced engineers a consistent reference to hold everyone to the same standard.

---

## Table of Contents

1. Repository Structure & Setup
2. Branching Strategy
3. Commit Practices
4. Pull Request / Merge Request Workflow
5. Code Review Etiquette
6. Tagging & Releases
7. Working with Regression & CI
8. Common Beginner Mistakes & How to Avoid Them
9. Quick Reference Checklist
10. Daily Routine — Start-of-Day and End-of-Day Steps
11. Fresh Graduate Fast-Start Guide (Clone → Branch → Commit → Push → PR → Merge)

---

# 1. Repository Structure & Setup

## 1.1 Standard Directory Layout

**Rule:** Every clone of the VIP repository shall follow the same top-level directory layout so that any engineer can find any file without asking.

**Steps to Follow:**
1. Keep all UVM agent code under `agents/`, one subfolder per agent.
2. Keep environment-level classes (env, scoreboard, config) under `env/`.
3. Keep sequences and sequence libraries under `seq/`.
4. Keep test classes under `tests/`.
5. Keep project documentation (plans, guidelines, RTM) under `docs/`.
6. Keep simulation run scripts, Makefiles, and regression lists under `sim/`.
7. Never place source files loosely in the repository root.

**Correct Example:**
```
100g_mac_vip/
├── agents/
│   ├── axi_agent/
│   ├── rs_agent/
│   └── mac_rst_agent/
├── env/
│   ├── mac_env_c.sv
│   └── mac_scoreboard_c.sv
├── seq/
│   ├── mac_base_seq_c.sv
│   └── mac_jumbo_frame_seq_c.sv
├── tests/
│   └── mac_base_test_c.sv
├── docs/
│   ├── coding_guidelines.md
│   └── verification_plan.md
├── sim/
│   ├── Makefile
│   └── regression_list.f
├── .gitignore
└── README.md
```

---

## 1.2 `.gitignore` Rules for a UVM Project

**Rule:** Simulation artifacts, waveform dumps, coverage databases, and personal/local config shall never be committed. A shared `.gitignore` at the repo root shall exclude them by default.

**Steps to Follow:**
1. Create a `.gitignore` file at the repository root before the first commit.
2. Add patterns for simulator-generated files (`*.log`, `*.vcd`, `*.fsdb`, `*.wlf`, `*.shm/`, `*.vpd`).
3. Add patterns for coverage databases (`*.ucdb`, `*.vdb`, `coverage_reports/`).
4. Add patterns for build/work directories (`work/`, `xcelium.d/`, `csrc/`, `*.o`, `*.so`).
5. Add patterns for personal/editor files (`.vscode/`, `*.swp`, `.DS_Store`).
6. Run `git status` after adding `.gitignore` to confirm generated files no longer show as untracked.

**Correct Example (`.gitignore`):**
```gitignore
# Simulation artifacts
*.log
*.vcd
*.fsdb
*.wlf
*.vpd
*.shm/
transcript

# Coverage
*.ucdb
*.vdb
coverage_reports/

# Build/work directories
work/
xcelium.d/
csrc/
simv*
*.o
*.so

# Editor / OS files
.vscode/
.idea/
*.swp
.DS_Store
```

**Incorrect Example (what NOT to do):**
```
$ git add .
$ git commit -m "add my test run"
# Oops - this just committed a 400MB waveform.vcd and the entire work/ directory
```

---

## 1.3 README and Onboarding Setup

**Rule:** The repository root shall contain a `README.md` that lets a new engineer clone, build, and run a sanity test within 15 minutes, with no tribal knowledge required.

**Steps to Follow:**
1. State the tool versions required (simulator, UVM version, Python version if used).
2. Give the exact clone command and any submodule/init steps.
3. Give the exact command to run a sanity regression.
4. Link to `docs/coding_guidelines.md` and this Git guidelines document.
5. Keep the README updated whenever setup steps change — an outdated README is worse than none.

**Correct Example (`README.md` excerpt):**
```markdown
## Quick Start
1. Clone: `git clone git@company-repo:100g_mac_vip.git`
2. Enter the sim directory: `cd 100g_mac_vip/sim`
3. Run sanity: `make TEST=mac_sanity_test_c`
4. See `docs/coding_guidelines.md` and `docs/git_guidelines.md` before your first PR.
```

---

# 2. Branching Strategy

## 2.1 Branch Naming Convention

**Rule:** Every branch name shall start with a type prefix, followed by the ticket ID and a short description, all in `kebab-case`.

**Steps to Follow:**
1. Choose a prefix: `feature/`, `bugfix/`, `hotfix/`, `release/`, `docs/`.
2. Add the ticket ID immediately after the prefix (e.g., `VIP-142`).
3. Add a short, hyphenated description of the change.
4. Never use your own name, a date, or "test" as the entire branch name.

**Correct Example:**
```
feature/VIP-142-jumbo-frame-support
bugfix/VIP-158-pause-timer-reload
hotfix/VIP-171-scoreboard-queue-leak
release/v1.3.0
docs/VIP-190-update-coding-guidelines
```

**Incorrect Example:**
```
haritha_branch
test123
my-fix
new-stuff-2
```

---

## 2.2 Branching From the Right Base

**Rule:** `feature/*` and `bugfix/*` branches shall always branch from the latest `develop`. `hotfix/*` branches shall branch from `main`. `release/*` branches shall branch from `develop` at the point a release is cut.

**Steps to Follow:**
1. Before branching, update your local base branch: `git checkout develop && git pull origin develop`.
2. Create your branch from the up-to-date base: `git checkout -b feature/VIP-142-jumbo-frame-support`.
3. For a hotfix, branch from `main` instead: `git checkout main && git pull && git checkout -b hotfix/VIP-171-scoreboard-queue-leak`.
4. Never branch from another engineer's in-progress feature branch unless intentionally stacking work (and say so in the PR description if you do).

**Correct Example:**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/VIP-142-jumbo-frame-support
```

**Incorrect Example:**
```bash
# Branching from an old local copy of develop that is 3 weeks stale
git checkout -b feature/VIP-142-jumbo-frame-support
# (forgot to pull first - branch now missing 3 weeks of fixes)
```

---

## 2.3 Keeping Feature Branches Short-Lived and Up to Date

**Rule:** Feature branches should live for a few days to at most ~2 weeks, and must be regularly synced with the base branch to avoid painful merge conflicts.

**Steps to Follow:**
1. Sync at least once a day if `develop` is actively moving: `git fetch origin && git rebase origin/develop`.
2. If the branch is shared with others, use `git merge origin/develop` instead of rebase (rebasing rewrites history and breaks shared branches).
3. If a feature is taking longer than 2 weeks, split it into smaller PRs behind a feature flag/config option rather than keeping one giant branch open.
4. Delete the branch immediately after it is merged.

**Correct Example:**
```bash
git fetch origin
git rebase origin/develop
# resolve any conflicts, then:
git push --force-with-lease origin feature/VIP-142-jumbo-frame-support
```

---

# 3. Commit Practices

## 3.1 Commit Message Format (Conventional Commits Style)

**Rule:** Every commit message shall follow the format `type(scope): short summary`, followed by an optional body explaining *why*, and a footer linking the ticket.

**Steps to Follow:**
1. Choose a `type`: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`.
2. Add a `scope` in parentheses — the component touched (`tx_agent`, `scoreboard`, `seq`, `env`).
3. Write a short summary in the imperative mood ("add", not "added"/"adds"), under 72 characters.
4. Leave a blank line, then add a body explaining the reasoning if the change isn't self-evident.
5. Add a footer line referencing the ticket: `Refs: VIP-142`.

**Correct Example — Commit Message List (use these as templates):**
```
feat(tx_agent): add jumbo frame randomization support

Adds a new constraint allowing frame_length to extend up to 9000 bytes
when jumbo mode is enabled in the agent config, per VIP-142.

Refs: VIP-142
```
```
fix(scoreboard): resolve queue leak on discarded frames

The compare task was not popping the expected-queue entry when a frame
was discarded mid-comparison, causing a slow memory leak over long
regressions.

Refs: VIP-171
```
```
test(pause): add zero-quanta PAUSE frame test case

Refs: VIP-158
```
```
docs(guidelines): update class naming convention to require _c suffix

Refs: VIP-190
```
```
refactor(seq): extract common config lookup into mac_base_seq_c

No functional change - moves duplicated pre_body() logic from three
sequences into the shared base sequence.

Refs: VIP-165
```
```
chore(sim): bump regression timeout from 10m to 20m for CI runners
```
```
perf(monitor): reduce transaction allocation overhead in m_rx_mon

Refs: VIP-183
```

**Incorrect Example:**
```
fixed stuff
update
wip
asdf
final fix pls work
Fixed the bug that Praveen found yesterday in the thing
```

---

## 3.2 Atomic Commits — One Logical Change per Commit

**Rule:** Each commit shall represent exactly one logical, self-contained change. Do not mix unrelated changes (e.g., a bug fix and a formatting pass) into a single commit.

**Steps to Follow:**
1. Before committing, run `git diff --stat` and ask: "is this one coherent change?"
2. If a commit mixes concerns, use `git add -p` to stage only the relevant hunks.
3. Split unrelated changes into separate commits, each with its own message.
4. Never combine "fix bug" and "reformat entire file" in one commit — reformatting buries the actual fix in review.

**Correct Example (two separate, atomic commits):**
```bash
git add env/mac_scoreboard_c.sv
git commit -m "fix(scoreboard): resolve queue leak on discarded frames"

git add agents/axi_agent/axi_driver_c.sv
git commit -m "refactor(tx_agent): apply 2-space indentation per style guide"
```

**Incorrect Example (one bloated commit):**
```bash
git add .
git commit -m "fix bug and cleanup code"
# 47 files changed - reviewer cannot tell what the actual fix was
```

---

## 3.3 What NOT to Commit

**Rule:** Never commit generated files, local waveform dumps, personal editor settings, or commented-out debug code left over from local development.

**Steps to Follow:**
1. Run `git status` before every commit and review the full file list — don't blindly `git add .`.
2. If you see `work/`, `*.vcd`, `*.log`, or similar, check that `.gitignore` is catching it; if not, add the pattern.
3. Remove any `` `uvm_info(..., UVM_NONE) `` or `$display` debug prints you added temporarily while developing, before committing.
4. Never commit commented-out blocks of old code "just in case" — Git history already preserves it; use `git log`/`git blame` to retrieve it if ever needed.

**Correct Example:**
```bash
git status
# On branch feature/VIP-142-jumbo-frame-support
# Changes not staged for commit:
#   modified:   agents/axi_agent/axi_driver_c.sv
# Untracked files:
#   work/                <- caught correctly, will not be added
git add agents/axi_agent/axi_driver_c.sv
git commit -m "feat(tx_agent): add jumbo frame randomization support"
```

**Incorrect Example:**
```systemverilog
// old code, keeping just in case
// if (frame.length > 1518) begin
//   frame.length = 1518;
// end
$display("DEBUG: got here 1");   // left-over debug print, must be removed
frame.length = new_length;
```

---

## 3.4 Sign-Off / Attribution

**Rule:** If the project requires a Developer Certificate of Origin (DCO) or sign-off line, every commit shall include it via `git commit -s`.

**Steps to Follow:**
1. Configure your name/email once: `git config --global user.name "Haritha K"` and `git config --global user.email "haritha@company.com"`.
2. Always commit with `-s` if the project mandates sign-off: `git commit -s -m "feat(tx_agent): add jumbo frame randomization support"`.
3. Verify the sign-off line appears: `git log -1` should show `Signed-off-by: Haritha K <haritha@company.com>`.

**Correct Example:**
```bash
git commit -s -m "feat(tx_agent): add jumbo frame randomization support"

# Resulting commit trailer:
# Signed-off-by: Haritha K <haritha@company.com>
```

---

# 4. Pull Request / Merge Request Workflow

## 4.1 PR Title and Description Template

**Rule:** Every PR shall use a standard template covering what changed, why, and how it was tested — a bare title with no description is not acceptable.

**Steps to Follow:**
1. Title the PR the same way as your primary commit: `feat(tx_agent): add jumbo frame randomization support`.
2. Fill in the description template (see below) — do not leave sections blank.
3. Link the ticket ID in the description, not just the branch name.
4. Attach regression/coverage results or a screenshot/log snippet if applicable.

**Correct Example (PR description template):**
```markdown
## What changed
Added jumbo frame randomization (up to 9000 bytes) to `axi_driver_c`,
gated behind a new `enable_jumbo` config field.

## Why
Required to close TC_021 (Jumbo Frame Detection) per the verification plan.

## How tested
- Ran `make TEST=mac_jumbo_frame_test_c` locally - 50/50 seeds passed.
- Full sanity regression (`make regress SUITE=sanity`) - 120/120 passed.
- Functional coverage for CC_MAC_006 (Jumbo Frame) now at 100%.

## Refs
VIP-142
```

**Incorrect Example:**
```markdown
Title: fix stuff
Description: (empty)
```

---

## 4.2 Linking PRs to Tickets

**Rule:** Every PR shall reference its tracking ticket both in the branch name and in the PR description, using the project's issue-linking keyword if supported (e.g., `Refs:`, `Closes:`).

**Steps to Follow:**
1. Use `Refs: VIP-142` for PRs that contribute to but don't fully close a ticket.
2. Use `Closes: VIP-142` only when the PR fully resolves the ticket (this auto-closes it on merge, if supported).
3. Never leave a PR with zero ticket reference — untraceable changes are not acceptable for a verification IP release.

**Correct Example:**
```
Closes: VIP-142
```
```
Refs: VIP-165 (partial - remaining sequences to follow in a separate PR)
```

---

## 4.3 Required Checks Before Requesting Review

**Rule:** A PR shall not be sent for review until the author has personally verified it locally.

**Steps to Follow:**
1. Run the full sanity regression locally or via CI and confirm 100% pass: `make regress SUITE=sanity`.
2. Run the project lint check: `make lint` (or the team's configured linter) and confirm zero violations.
3. Search your diff for leftover debug code: `git diff origin/develop... | grep -n "display\|UVM_NONE"`.
4. Confirm no unrelated files are included: `git diff --stat origin/develop...`.

**Correct Example (pre-review checklist run):**
```bash
make regress SUITE=sanity      # 120/120 PASSED
make lint                       # 0 errors, 0 warnings
git diff --stat origin/develop... HEAD
#  agents/axi_agent/axi_driver_c.sv | 24 ++++++++++++++
#  seq/mac_jumbo_frame_seq_c.sv           | 18 ++++++++
#  2 files changed - only the intended files
```

---

## 4.4 Reviewer Approvals and Merge Strategy

**Rule:** A PR requires a minimum of **1 approval** for docs/test-only changes and **2 approvals** for any change to agents, env, or scoreboard code, before it can be merged. Squash-merge is the default strategy; a merge commit is used only for `release/*` branches.

**Steps to Follow:**
1. Request review from at least one senior engineer if you are a fresh graduate submitting your first few PRs.
2. Do not self-merge — even if you have permission, wait for the required approvals.
3. Use **Squash and merge** for `feature/*` and `bugfix/*` branches into `develop`, so `develop` history stays one-commit-per-PR and readable.
4. Use a regular **merge commit** (no squash, no rebase) when merging a completed `release/*` branch into `main`, to preserve the full release history.

**Correct Example (merge summary shown by most Git hosts):**
```
Squash and merge pull request #58 from feature/VIP-142-jumbo-frame-support
feat(tx_agent): add jumbo frame randomization support (#58)

Approved by: praveen-k, sudha-r
```

---

# 5. Code Review Etiquette

## 5.1 Reviewer Responsibilities and Turnaround

**Rule:** Reviewers shall respond to a PR within 1 business day, either with approval, requested changes, or an explicit "will review by [date]" if busy.

**Steps to Follow:**
1. Check the diff for adherence to `docs/coding_guidelines.md` (naming, formatting, error handling).
2. Confirm the "How tested" section in the PR description is credible (matches the size/risk of the change).
3. Leave specific, actionable comments — point to a line and suggest the fix, don't just say "this is wrong."
4. Approve once satisfied, or use "Request changes" with a clear list of required fixes.

**Correct Example (review comment):**
```
Line 42: This constraint doesn't exclude the PAUSE EtherType, so a
randomly generated jumbo frame could accidentally collide with
0x8808. Suggest adding: `ethertype != `MAC_PAUSE_ETHERTYPE;`
```

**Incorrect Example (unhelpful review comment):**
```
this looks wrong
```

---

## 5.2 Responding to Review Comments (Fresher Guidance)

**Rule:** Address review feedback with new commits pushed to the same branch — do **not** force-push over history that a reviewer has already commented on, unless explicitly asked to squash/clean up before final merge.

**Steps to Follow:**
1. Make the requested change locally.
2. Commit it as a small follow-up commit: `git commit -m "fix(tx_agent): exclude PAUSE ethertype from jumbo constraint"`.
3. Push normally (no `--force`): `git push origin feature/VIP-142-jumbo-frame-support`.
4. Reply to the reviewer's comment marking it resolved, referencing the new commit hash if helpful.
5. Only rebase/force-push if the reviewer or team lead explicitly asks you to "clean up the history" before merge — and always use `--force-with-lease`, never plain `--force`.

**Correct Example:**
```bash
# after making the fix
git add agents/axi_agent/axi_driver_c.sv
git commit -m "fix(tx_agent): exclude PAUSE ethertype from jumbo constraint"
git push origin feature/VIP-142-jumbo-frame-support
```

**Incorrect Example (what a fresher should avoid doing):**
```bash
git commit --amend
git push --force origin feature/VIP-142-jumbo-frame-support
# rewrites history the reviewer already commented on - their comments
# may now point to the wrong lines, and collaborators' local copies break
```

---

## 5.3 Resolving Merge Conflicts (Step-by-Step for First-Timers)

**Rule:** Merge conflicts shall be resolved locally, deliberately, and re-tested before pushing — never resolved blindly by accepting "theirs" or "ours" without reading the conflicting code.

**Steps to Follow (a walkthrough for someone doing this for the first time):**
1. Update your branch against the base: `git fetch origin` then `git merge origin/develop` (or `git rebase origin/develop` if your branch is not shared with anyone else).
2. Git will report conflicted files: `CONFLICT (content): Merge conflict in agents/axi_agent/axi_driver_c.sv`.
3. Open the file — Git marks the conflict clearly:
   ```systemverilog
   <<<<<<< HEAD
   frame.length = new_length;
   =======
   frame.length = clamp_length(new_length);
   >>>>>>> origin/develop
   ```
4. Read both versions and decide the correct combined result — do not just delete one side without understanding it. Here, `develop` added a safety clamp that should be kept:
   ```systemverilog
   frame.length = clamp_length(new_length);
   ```
5. Remove the `<<<<<<<`, `=======`, and `>>>>>>>` marker lines completely.
6. Re-run the local sanity regression to make sure your resolution didn't break anything: `make regress SUITE=sanity`.
7. Stage and complete the merge: `git add agents/axi_agent/axi_driver_c.sv` then `git commit` (for a merge) or `git rebase --continue` (for a rebase).
8. Push: `git push origin feature/VIP-142-jumbo-frame-support` (add `--force-with-lease` only if you rebased).

**Correct Example (full conflict resolution session):**
```bash
git fetch origin
git merge origin/develop
# CONFLICT (content): Merge conflict in agents/axi_agent/axi_driver_c.sv
# Automatic merge failed; fix conflicts and then commit the result.

# ... open file, resolve as shown above, save ...

make regress SUITE=sanity        # confirm still passing
git add agents/axi_agent/axi_driver_c.sv
git commit
git push origin feature/VIP-142-jumbo-frame-support
```

**Incorrect Example:**
```bash
git checkout --theirs agents/axi_agent/axi_driver_c.sv
git add .
git commit -m "fixed conflict"
# blindly discarded your own change without reading what it was
```

---

# 6. Tagging & Releases

## 6.1 Semantic Versioning for VIP Releases

**Rule:** Every release shall be tagged using semantic versioning: `vMAJOR.MINOR.PATCH`.

**Steps to Follow:**
1. Increment **MAJOR** for breaking changes to the VIP's interface/API (config fields removed/renamed, sequence API changes).
2. Increment **MINOR** for backward-compatible new features (new test cases, new coverage points, new sequences).
3. Increment **PATCH** for backward-compatible bug fixes only.
4. Never reuse or move a tag once pushed — create a new patch version instead.

**Correct Example:**
```
v1.0.0   - initial production release
v1.1.0   - added jumbo frame support (new feature)
v1.1.1   - fixed scoreboard queue leak (bug fix only)
v2.0.0   - renamed mac_env_cfg_c fields, breaking existing tests (breaking change)
```

---

## 6.2 Creating a Release Tag

**Rule:** Tags shall be created only from `main`, only after the release branch has passed full regression and coverage closure, and shall be annotated (not lightweight) so they carry a message and author.

**Steps to Follow:**
1. Merge the completed `release/*` branch into `main` (merge commit, not squash — see 4.4).
2. Checkout `main` and pull: `git checkout main && git pull origin main`.
3. Create an annotated tag: `git tag -a v1.1.0 -m "Release v1.1.0: jumbo frame support"`.
4. Push the tag explicitly (tags are not pushed by default): `git push origin v1.1.0`.

**Correct Example:**
```bash
git checkout main
git pull origin main
git tag -a v1.1.0 -m "Release v1.1.0: jumbo frame support, closes VIP-142"
git push origin v1.1.0
```

---

## 6.3 Release Branch Freeze and Hotfix Process

**Rule:** Once a `release/*` branch is cut, only bug fixes are allowed on it — no new features. Post-release production bugs are handled via `hotfix/*` branches off `main`, merged back into both `main` and `develop`.

**Steps to Follow:**
1. Cut the release branch from `develop`: `git checkout -b release/v1.2.0 develop`.
2. Only cherry-pick or commit bug fixes onto `release/v1.2.0` from this point.
3. After tagging and releasing, if a bug is found in production: `git checkout -b hotfix/VIP-171-scoreboard-queue-leak main`.
4. After the hotfix is verified, merge it into **both** `main` (tag a new patch release) and `develop` (so the fix isn't lost in the next release).

**Correct Example:**
```bash
git checkout -b hotfix/VIP-171-scoreboard-queue-leak main
# ... fix, test, commit ...
git checkout main
git merge --no-ff hotfix/VIP-171-scoreboard-queue-leak
git tag -a v1.1.1 -m "Hotfix: scoreboard queue leak"
git push origin main v1.1.1

git checkout develop
git merge --no-ff hotfix/VIP-171-scoreboard-queue-leak
git push origin develop
```

---

# 7. Working with Regression & CI

## 7.1 Never Merge with Failing Checks

**Rule:** A PR with a failing regression, lint check, or coverage gate shall never be merged, regardless of urgency.

**Steps to Follow:**
1. Treat a red CI check as a hard blocker, not a suggestion.
2. If CI fails, reproduce locally, fix, push a new commit, and wait for CI to go green again.
3. If a failure is a known, pre-existing flaky test unrelated to your change, flag it to the team lead — do not just merge past it silently.

**Correct Example (CI status before merge):**
```
✔ Lint check          passed
✔ Sanity regression    passed (120/120)
✔ Coverage gate        passed (95.4% ≥ 95% target)
-> PR is mergeable
```

**Incorrect Example:**
```
✘ Sanity regression    failed (118/120)
-> "It's probably fine, I'll merge anyway" - NOT acceptable
```

---

## 7.2 Registering a New Test in the Regression Suite

**Rule:** Any new test class must be added to the appropriate regression list file in the same PR that introduces it — a test that exists but isn't registered will never actually run in CI.

**Steps to Follow:**
1. Add the new test file under `tests/`.
2. Open the relevant regression list, e.g. `sim/regression_list.f`.
3. Add one line per new test with its name and any required seed count.
4. Commit both the new test file and the updated regression list together in one commit.

**Correct Example (`sim/regression_list.f` diff):**
```diff
  mac_sanity_test_c        seeds=5
  mac_pause_test_c         seeds=10
+ mac_jumbo_frame_test_c   seeds=20
```

---

## 7.3 Handling Large/Binary Files (Git LFS)

**Rule:** Any file expected to regularly exceed 5 MB (reference waveforms kept intentionally for debug reference, binary coverage snapshots archived for a milestone) shall be tracked via Git LFS, not committed directly.

**Steps to Follow:**
1. Install Git LFS once per machine: `git lfs install`.
2. Track the file type: `git lfs track "*.ucdb"`.
3. Commit the resulting `.gitattributes` file.
4. Add and commit the large file normally — LFS handles it transparently from here.

**Correct Example:**
```bash
git lfs install
git lfs track "*.ucdb"
git add .gitattributes
git commit -m "chore(lfs): track coverage database files via Git LFS"

git add milestone_coverage.ucdb
git commit -m "chore(coverage): archive milestone-4 coverage snapshot"
```

---

# 8. Common Beginner Mistakes & How to Avoid Them

## 8.1 Committing Directly to `main` or `develop`

**Mistake:** Making changes and committing straight onto `main`/`develop` instead of a feature branch.

**Why it's a problem:** It bypasses code review entirely and can break the shared branch for everyone.

**How to avoid it:**
1. Always check your current branch before editing: `git branch --show-current`.
2. If it says `main` or `develop`, stop and create a feature branch first: `git checkout -b feature/VIP-XXX-description`.
3. Ask your team lead to enable branch protection on `main`/`develop` so direct pushes are blocked at the server level.

---

## 8.2 Force-Pushing to a Shared Branch

**Mistake:** Running `git push --force` on `develop`, `main`, or any branch other engineers are also using.

**Why it's a problem:** It can silently discard other people's commits.

**How to avoid it:**
1. Never run plain `--force` on a shared branch — full stop.
2. On your *own* feature branch, if you must rewrite history after a rebase, use `git push --force-with-lease`, which fails safely if someone else has pushed to that branch since you last fetched.

---

## 8.3 Losing Work by Switching Branches Without Committing/Stashing

**Mistake:** Running `git checkout other-branch` while you have uncommitted changes, and losing track of them.

**Why it's a problem:** Uncommitted changes can be overwritten or become confusing to track across branches.

**How to avoid it:**
1. Before switching branches, either commit your work-in-progress (`git commit -m "wip: partial jumbo frame constraint"`) or stash it: `git stash push -m "wip jumbo frame constraint"`.
2. When you come back, restore it: `git stash pop`.
3. Get in the habit of running `git status` before every `git checkout`.

**Correct Example:**
```bash
git status
# Changes not staged for commit: agents/axi_agent/axi_driver_c.sv
git stash push -m "wip jumbo frame constraint"
git checkout bugfix/VIP-158-pause-timer-reload
# ... do the other work ...
git checkout feature/VIP-142-jumbo-frame-support
git stash pop
```

---

## 8.4 Committing Secrets, Credentials, or License Files

**Mistake:** Accidentally committing a license server config, API key, or password file.

**Why it's a problem:** Once pushed, it exists in Git history forever unless the history is rewritten (which is disruptive for everyone).

**How to avoid it:**
1. Add known credential file patterns to `.gitignore` from day one (`*.key`, `license.dat`, `.env`).
2. Never paste real credentials into a commit "temporarily" — use environment variables or a local, git-ignored config file instead.
3. If a secret is accidentally committed, notify the team lead immediately so the credential can be rotated and the history scrubbed — do not just delete the file in a new commit (the secret still exists in history).

---

## 8.5 Not Pulling/Rebasing Before Starting New Work

**Mistake:** Branching off a `develop` that is days or weeks out of date, leading to large, painful conflicts later.

**Why it's a problem:** The longer a branch diverges from its base, the harder and riskier the eventual merge becomes.

**How to avoid it:**
1. Always run `git pull origin develop` (while on `develop`) immediately before creating a new branch.
2. If your feature branch already exists and is getting old, sync it regularly (see 2.3) rather than waiting until the end.

---

# 9. Quick Reference Checklist

- [ ] Branch created from an up-to-date base, named `type/TICKET-ID-short-description`
- [ ] Commits follow `type(scope): summary` format, one logical change per commit
- [ ] No generated files, waveforms, debug prints, or commented-out code committed
- [ ] `.gitignore` covers all simulator/coverage/build artifacts
- [ ] Sanity regression + lint run locally and passing before requesting review
- [ ] PR description filled in completely (what/why/how tested), ticket linked
- [ ] Required reviewer approvals obtained (1 for docs/tests, 2 for agent/env/scoreboard code)
- [ ] Squash-merge used for feature/bugfix branches; merge commit only for release branches
- [ ] New tests registered in the regression list in the same PR
- [ ] Never force-push to `main`/`develop`; use `--force-with-lease` only on your own branch
- [ ] Release tags are annotated, semantic-versioned, and pushed explicitly

---

# 10. Daily Routine — Start-of-Day and End-of-Day Steps

A short checklist every engineer (and especially every fresher) should run through at the start and end of each working day, regardless of what task is in progress.

## 10.1 Start-of-Day Steps

**Rule:** Before writing any code each day, sync your local repo and your working branch with the latest upstream changes — never start editing on a stale branch.

**Steps to Follow:**
1. Check which branch you're on: `git branch --show-current`.
2. Make sure you have no uncommitted work from yesterday sitting around unexpectedly: `git status`.
3. Update your local `develop` (or `main`, if that's your base): 
   ```bash
   git checkout develop
   git pull origin develop
   ```
4. Go back to your feature branch and bring it up to date with the latest `develop`:
   ```bash
   git checkout feature/VIP-142-jumbo-frame-support
   git fetch origin
   git rebase origin/develop      # only if the branch is yours alone
   # OR
   git merge origin/develop       # if the branch is shared with others
   ```
5. Resolve any conflicts immediately (see Section 5.3) while the change is fresh in your mind — don't leave conflicts for later in the day.
6. Skim any new Slack/email/ticket comments on your assigned tickets before diving in, in case scope changed overnight.
7. Confirm the environment still builds/runs before making new changes: run a quick sanity test.

**Correct Example (start-of-day sequence):**
```bash
git branch --show-current
# feature/VIP-142-jumbo-frame-support

git status
# nothing to commit, working tree clean

git checkout develop
git pull origin develop

git checkout feature/VIP-142-jumbo-frame-support
git fetch origin
git rebase origin/develop

make TEST=mac_sanity_test_c      # confirm environment is healthy before starting
```

---

## 10.2 End-of-Day Steps

**Rule:** Never leave your working directory with uncommitted or unpushed changes at the end of the day — either commit and push your progress, or explicitly stash it with a clear note.

**Steps to Follow:**
1. Review everything you touched today: `git status` and `git diff`.
2. Remove any leftover debug prints or commented-out code (see Section 3.3).
3. If the work is complete enough to be a meaningful commit, commit it with a proper message (see Section 3.1) — don't leave it as only-local changes overnight.
4. Push your branch so your work is backed up remotely: `git push origin feature/VIP-142-jumbo-frame-support`.
5. If the work is genuinely mid-thought and not commit-worthy yet, stash it with a descriptive message instead of leaving it dangling: `git stash push -m "wip: jumbo frame constraint - EtherType exclusion not yet added"`.
6. If your PR is open, check for any new review comments and reply or note that you'll address them tomorrow.
7. Update your ticket/task tracker with today's progress so the next day (or a teammate, if needed) can pick up smoothly.

**Correct Example (end-of-day sequence):**
```bash
git status
git diff agents/axi_agent/axi_driver_c.sv

# work is in a good, committable state:
git add agents/axi_agent/axi_driver_c.sv
git commit -m "feat(tx_agent): add jumbo frame randomization support

Refs: VIP-142"
git push origin feature/VIP-142-jumbo-frame-support
```

**Correct Example (work not yet commit-worthy):**
```bash
git stash push -m "wip: jumbo frame constraint - EtherType exclusion not yet added"
git status
# working tree clean - safe to close laptop, nothing is at risk of being lost
```

**Incorrect Example (what NOT to do at end of day):**
```bash
# Just closing the laptop with hours of uncommitted, unstashed changes
# sitting in the working directory - at risk from a machine crash,
# accidental branch switch, or disk issue, and invisible to teammates.
```

---

## 10.3 Daily Routine Quick Checklist

**Start of Day:**
- [ ] `git status` — confirm nothing unexpected is lying around
- [ ] `git checkout develop && git pull origin develop`
- [ ] `git checkout <your-branch>` and sync it (`rebase` if solo, `merge` if shared)
- [ ] Resolve any conflicts immediately
- [ ] Run a quick sanity test before starting new work
- [ ] Check tickets/comments for scope changes

**End of Day:**
- [ ] `git status` / `git diff` — review everything touched today
- [ ] Remove leftover debug prints / commented-out code
- [ ] Commit meaningful progress with a proper message, or stash with a clear note
- [ ] Push your branch so work is backed up remotely
- [ ] Check/respond to open PR review comments
- [ ] Update ticket/task tracker with today's status

---

# 11. Fresh Graduate Fast-Start Guide

A complete first contribution, start to finish, assuming no prior Git experience.

**Step 1 — One-time setup**
```bash
git config --global user.name "Your Name"
git config --global user.email "you@company.com"
git clone git@company-repo:100g_mac_vip.git
cd 100g_mac_vip
```

**Step 2 — Get the latest code and create your branch**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/VIP-200-add-vlan-dei-test
```

**Step 3 — Make your change**
```bash
# edit files in your editor, e.g. tests/mac_vlan_dei_test_c.sv
git status
# check what changed before staging anything
```

**Step 4 — Commit your change**
```bash
git add tests/mac_vlan_dei_test_c.sv sim/regression_list.f
git commit -m "test(vlan): add VLAN DEI verification test case

Adds mac_vlan_dei_test_c and registers it in the sanity regression list.

Refs: VIP-200"
```

**Step 5 — Push your branch**
```bash
git push -u origin feature/VIP-200-add-vlan-dei-test
```

**Step 6 — Open a Pull Request**
1. Go to the repository on the Git host (GitHub/GitLab/Bitbucket).
2. Click "Create Pull Request" for your branch into `develop`.
3. Fill in the PR template (see 4.1): what changed, why, how tested.
4. Add `Refs: VIP-200` and request review from your mentor/senior engineer.

**Step 7 — Respond to review feedback**
```bash
# after making a requested fix
git add tests/mac_vlan_dei_test_c.sv
git commit -m "fix(vlan): correct DEI bit constraint per reviewer feedback"
git push origin feature/VIP-200-add-vlan-dei-test
```

**Step 8 — Merge (done by reviewer/lead once approved)**
- Reviewer approves → Squash and merge into `develop`.
- Your branch is deleted automatically (or delete it yourself): `git branch -d feature/VIP-200-add-vlan-dei-test`.

**Step 9 — Clean up and start your next task**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/VIP-201-next-task
```

**Congratulations — that's the full loop you'll repeat for every task.**
