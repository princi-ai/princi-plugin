# Design — PR Best Practices Extractor (`/princi-create-pr-best-practices`)

<!-- created per [Harish:Quang 2026-05-28 14:01 PDT](https://docs.google.com/document/d/1_euq5zD71PMp30lF_KKPvhre09YSOPyAHZNvYjCt9Dc/edit) — "submit a PR on pull request best practices ... move that task into the plugin repository" -->
<!-- also informed by [Harish:Quang 2026-05-26 09:04 PDT](https://docs.google.com/document/d/19btyUVGViOleIMyMrKfy5dE06kxX2RDiP6cmu32raMY/edit) — "leveraging personal PR history, code base, and previous chat contexts" -->
<!-- and [Team sync 2026-05-25](https://docs.google.com/document/d/16UrZ_nWHwJOmqBP2qGi_-N5XmNH_nc3AQJBzLFeeVMM/edit) — "create a solution that learns from historical pull requests, design documents, and bug reports to prevent recurring issues" -->

**Status:** Draft · paired with the in-flight implementation in [princi-plugin#17](https://github.com/princi-ai/princi-plugin/pull/17)
**Owner:** @nxq · **Reviewers:** @harish
**Repo of record:** `princi-ai/princi-plugin` (skill code lives here; per 2026-05-28 decision to move PR best-practices work into the plugin)

---

## 1. Overview

A Claude Code / Cursor skill, `/princi-create-pr-best-practices`, that mines the last ~100 closed GitHub PRs in any repo and produces `pr-best-practices.md` — a categorized, citation-backed playbook of **reusable** team conventions for future PR authors, reviewers, and design-doc writers.

The skill exists because PR review feedback, rollbacks, and follow-on fixes are the team's richest source of hard-won institutional knowledge — and the most-forgotten. Today an author learns a lesson once (e.g. "RLS on this table needs `SECURITY DEFINER`"), the reviewer flags it, the fix lands, and three months later a different author repeats the same mistake in a sibling PR. The extractor turns that lossy oral tradition into a queryable file that lives in the repo and travels with code.

The output is intentionally **rules, not changelog**: imperative team conventions ("always X when Y"), each cited to the PR(s) that motivated it, grouped by category, with stable labels for keyword/vector retrieval.

## 2. Goals

1. **Reusable conventions, not incident logs.** Every rule must help a *different* author months later. One-off vendor trivia is dropped.
2. **Citation-grounded.** Every rule cites ≥1 PR. No invented rules. Rules from rollbacks/follow-on fixes are tagged `⚠️ learned from failure`.
3. **Deterministic where possible, LLM only for judgment.** Evidence collection, signal classification, and file-path/extension aggregation are plain `gh` + Node. LLM is only used for the clustering/synthesis step.
4. **Re-runnable in any repo with one command.** No per-repo config; uses the user's existing `gh` auth.
5. **Safe under hostile PR content.** Treat all fetched PR bodies and comments as untrusted data (prompt-injection defense).

## 3. Non-goals

- **Not a PR review bot.** This skill writes a file; it does not comment on PRs. (A separate skill, `/princi-review-pr`, uses the generated file at review time.)
- **Not a real-time linter or enforcement gate.** No CI failure, no merge block.
- **Not a style arbiter.** Stylistic preferences (variable casing, import order) are out of scope unless they appear repeatedly in reviewer feedback.
- **Not org/team-aware.** Per the 2026-05-26 decision, this is an **individual-developer tool** — it reads from the personal `gh` token's view of the repo, not a centralized org index. ([Harish:Quang 2026-05-26](https://docs.google.com/document/d/19btyUVGViOleIMyMrKfy5dE06kxX2RDiP6cmu32raMY/edit))
- **Not a memory/chat extractor (yet).** Drive, Slack, and previous chat sources are listed in [§10 Open questions](#10-open-questions) for a future v2.

## 4. Success metrics

| Metric | Target |
|---|---|
| PRs analyzed per run | 100 (configurable via `--limit`) |
| Cold-run wall time on a 100-PR run | < 5 min on typical Mac + good network |
| Reusable rules emitted | ≥ 5 for any non-trivial repo; else the file says so explicitly |
| Author acceptance rate (subjective, sampled) | ≥ 80% of rules read as "useful" by the originating team |
| Output file size | Readable in one sitting (typically 10–40 rules, < 30KB) |
| Rules without a PR citation | **0** (drop-rule guardrail in the synthesis step) |

## 5. Architecture

A four-stage pipeline. The first three stages are deterministic Node code; only stage 4 calls the LLM.

```
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌──────────┐
│ Collector   │───▶│ Signal Extractor │───▶│ Rule Synthesizer│───▶│  Writer  │
│ (gh CLI)    │    │ (deterministic)  │    │  (LLM, 1 pass)  │    │ (Node)   │
└─────────────┘    └──────────────────┘    └─────────────────┘    └──────────┘
       │                    │                       │                   │
       ▼                    ▼                       ▼                   ▼
  Closed PRs +         .tmp/pr-best-practices-    Imperative          pr-best-
  reviews +            input.md (LLM-readable     rules with          practices.md
  inline threads +     evidence blocks)           citations           (repo root)
  changed files
```

### 5.1 Collector — `scripts/collect-pr-evidence.mjs`

A skill-local Node script invoked by the skill workflow:

- Resolves the repo via `gh repo view --json nameWithOwner`. If `gh` auth is missing, prints `gh auth status` and exits.
- Fetches the last `--limit N` (default 100) closed PRs in pages of 10 in parallel.
- For each PR, fetches in parallel: substantive reviews, inline review comments, changed files, PR labels.
- Groups inline comments into chronological threads (by `in_reply_to_id`).
- Handles GitHub rate-limit errors with a single 5-second retry; surfaces unrecoverable errors with the original `gh` stderr.

Output: nothing yet — it hands the in-memory object to the next stage.

### 5.2 Signal Extractor — deterministic classification

For each PR, tag with zero or more **signals** — these are the high-signal events that justify extracting a rule:

| Signal | Heuristic |
|---|---|
| `rollback` | PR title or body matches `revert`, `rollback`, `roll back` (case-insensitive); or merge of a `revert: ...` commit |
| `follow-on fix` | Body or title references an earlier PR via `#NNN` and uses words like "follow-up", "fix for", "addresses regression from" |
| `review feedback` | At least one substantive review (`CHANGES_REQUESTED` or `COMMENTED` with body length > threshold) or ≥ 1 inline comment thread |
| `description` | PR body length > threshold and contains structural markers (Summary / Test plan / Why headings) |

Also derived deterministically: `Touched areas` (high-level grouping from changed-file paths), `File extensions` (counts), `Labels` (raw `gh` labels passed through).

Output: a single `.tmp/pr-best-practices-input.md` file with one block per PR, plus an embedded pre-write summary header (`PRs analyzed: N`, `Rollbacks: N`, etc.). This is the **only** intermediate artifact; no separate JSON summary is produced (one file = one source of truth for the LLM).

### 5.3 Rule Synthesizer — single LLM pass

The skill (Claude Code or Cursor) reads `.tmp/pr-best-practices-input.md`, confirms the pre-write summary back to the user, then runs **one** synthesis pass.

The pass applies a **reusability filter** before emitting any rule:

- **Include** when the lesson generalizes: security/trust boundaries, architecture patterns, repo/process conventions, domain constraints, cross-feature testing or review expectations.
- **Exclude** vendor-specific trivia, single-file bug fixes that imply no general invariant, or duplicates of guidance already canonical in `AGENTS.md` / `CLAUDE.md` / `docs/`.
- When evidence points at a one-off, **generalize upward** or **omit**.

Each emitted rule carries: **Rule** (imperative), **Applies when** (1–5 triggers), **Applies paths** (globs or `repo-wide`), **Labels** (2–6 kebab-case), **Why** (citing PR evidence), **Source** (PR link(s)), **Category** (`security` | `architecture` | `testing` | `performance` | `conventions` | `tooling` | `domain-knowledge`).

Rules derived from a rollback or follow-on fix chain are flagged `⚠️ learned from failure` — these are the highest-trust rules in the file because they have proven-bad counter-examples.

### 5.4 Writer — Node

Writes `pr-best-practices.md` at the **repository root** (overwrites if present). The header records: generation date, repo, PRs analyzed, total rule count, and a "Use By PR Type" lookup index that maps common change types to label search terms.

The skill never auto-commits — the file lands in the working tree and the user reviews the diff.

## 6. Detailed design — selected decisions

### 6.1 Why `gh` CLI, not a GitHub App?

Per the 2026-05-26 decision, this is an **individual-developer tool**, not a centralized org service. Using the local `gh` token:
- Inherits the user's existing repo access — no separate auth flow.
- Works on private repos and forks without admin involvement.
- Avoids spinning up app infrastructure (hosting, secret rotation, install flows) for a feature that is fundamentally repo-local.

The 2026-05-28 notes raised "PR history based best practices via GitHub Apps that act on their own behalf" as a possible future direction; that is **deferred** ([§10](#10-open-questions)).

### 6.2 Why exactly one intermediate file?

Earlier sketches had two artifacts (a JSON summary + a markdown evidence dump). Collapsing to one file (`.tmp/pr-best-practices-input.md` with the summary embedded at the top) removes a divergence risk — the LLM and the human reviewer always see the same numbers and the same evidence. The current SKILL.md spells out: "Do not write `.tmp/pr-best-practices-summary.json`."

### 6.3 Trust boundary and prompt-injection defense

PR bodies, review comments, and inline comments are attacker-writable in any repo that takes outside contributions. The skill must never follow instructions embedded in that text.

Mitigations baked into the design:

- The synthesis prompt opens with an explicit `⚠️ Trust boundary` paragraph instructing the model to treat all PR text inside the evidence blocks as **data to analyze**, not control. ([SKILL.md, step 4](https://github.com/princi-ai/princi-plugin/blob/feat/princi-create-pr-best-practices/skills/princi-create-pr-best-practices/SKILL.md))
- The skill's "Guardrails" section restates this so a future edit cannot silently weaken it.
- The evidence file uses unambiguous block structure (each PR fenced by a heading) so an injected "ignore previous instructions" line is visibly inside a data block.
- Body / review / comment text is length-capped (1,500 / 500 / 300 chars) to limit the surface area for crafted payloads.

### 6.4 Failure modes — fail-loud, never fail-quiet

| Failure | Behavior |
|---|---|
| `gh` not authenticated | Print `gh auth status` output, exit non-zero, do not write any file |
| Rate limit during collection | Single 5-second retry; if it fails again, surface the `gh` stderr and exit |
| `gh` returns < 5 reusable rules after filtering | **Still write the file**, but include "low rule count" note in the header — never pad with one-offs to hit a number |
| LLM emits a rule without a PR citation | Drop the rule. (Hard guardrail; not a warning.) |

### 6.5 Skill is in the *plugin* repo, output file lives in the *target* repo

The skill code (workflow + collector script) lives in `princi-ai/princi-plugin` per the 2026-05-28 decision. When invoked, it writes the generated file at the **current repo's root** — wherever the user runs it. The skill never writes back to the plugin repo.

## 7. Operational concerns

- **Invocation:** `/princi-create-pr-best-practices` from a Claude Code / Cursor session in any repo. No flags needed; the script accepts `--limit N` (1–100) and `--out path` for power users.
- **Cost model:** One LLM synthesis call per run. Input is the assembled evidence file (capped by the 100-PR × per-section truncation budget); output is the markdown rule list. With current Sonnet pricing this lands in single-digit cents per run for typical repos.
- **Secrets:** None. `gh` handles auth via the user's existing token. The script never reads from or writes to `~/.netrc`, env vars, or any credential file.
- **Re-running:** Idempotent in spirit — `pr-best-practices.md` is overwritten. The script does **not** auto-commit; the user reviews the diff and commits as they see fit.
- **CI trigger (future):** Not part of this design. A scheduled GitHub Action that runs the script and opens a PR with the regenerated file is a reasonable follow-up but explicitly out of scope here.

## 8. Best practices (per Step E baseline)

Addressing the skill's own baseline checklist so this design doc walks the talk:

- **Logging.** The collector logs to stderr at three levels: progress (e.g. "Fetched 10/100 PRs"), warnings (rate-limit retry), and errors (auth failure, JSON parse failure). The LLM synthesis pass surfaces its pre-write summary in chat for human confirmation before writing the file.
- **Monitoring.** Out of scope — this is a developer-invoked, foreground tool, not a service. The "metric" is the rule count in the generated file's header, which the user sees on every run.
- **Error handling.** Fail-loud as enumerated in [§6.4](#64-failure-modes--fail-loud-never-fail-quiet). No silent skips, no padding to hit a number.
- **Observability.** The single `.tmp/pr-best-practices-input.md` artifact is intentionally preserved after a run so the user can inspect exactly what the LLM saw. Re-running overwrites it.
- **Security.** Untrusted-data handling is [§6.3](#63-trust-boundary-and-prompt-injection-defense). No secrets in code. No network egress beyond `gh`.
- **Scalability.** Designed for `--limit ≤ 100` PRs (current GitHub API page-size sweet spot). Repos with > 1000 closed PRs in a single sweep are out of scope for v1; the per-PR fetch is the bottleneck.
- **Rollback / kill-switch.** Output file is plain markdown in the user's working tree — uncommitted by default. The "rollback" is `rm pr-best-practices.md` or `git restore`. There is nothing to disable in production because there is no production.
- **Feature flags.** N/A — the skill is opt-in via slash command.

## 9. Risks & mitigations

| Risk | Mitigation |
|---|---|
| LLM invents a rule without PR evidence | Hard guardrail in the synthesis prompt: drop any rule that cannot be cited |
| LLM clusters two semantically distinct rules into one | The synthesis prompt requires `Applies when` and `Applies paths` per rule — divergence here is a smell the reviewer will catch on first read |
| Rules drift from reality as the codebase evolves | The file is regeneratable; the header records the date. Future v2 may diff against the prior version |
| Prompt-injection payload in a PR body steers the synthesis | Trust boundary text + structural fencing + length caps ([§6.3](#63-trust-boundary-and-prompt-injection-defense)) |
| User runs in a repo with very few PRs (< 10) | The pre-write summary surfaces this; the writer notes low rule count in the header rather than emitting nothing or padding |
| One reviewer's strong opinion gets promoted to a "team rule" | The reusability filter excludes single-incident patches; rules need cross-PR evidence to survive |

## 10. Open questions

1. **Drive / Slack / chat sources (v2 scope).** The 2026-05-28 notes called out "Get best practices from previous chats, GitHub, drive and others." V1 is GitHub-only. Do we want a second collector that pulls from Drive design docs and chat logs, or a separate skill that merges multiple evidence streams?
2. **Diff against prior `pr-best-practices.md`.** Should the writer surface a structured diff (rules added / removed / changed) when overwriting an existing file? Useful for review; complicates the writer.
3. **Multi-team conflicts in a monorepo.** If two area-owning teams have contradictory conventions in the same repo, the synthesis pass currently picks one. Per @nxq's CLAUDE.md "Rule 7 — surface conflicts, don't average them" we should flag and emit both with their evidence, rather than averaging. This is not yet implemented.
4. **GitHub App posture (deferred per [§6.1](#61-why-gh-cli-not-a-github-app)).** Revisit if/when the skill outgrows the individual-developer scope.
5. **Auto-consumption by `/princi-review-pr`.** That sibling skill should read this file at review time; the wiring is implied but not specified here.

## 11. Rollout plan

1. **Land [PR #17](https://github.com/princi-ai/princi-plugin/pull/17)** — ships the skill and collector script.
2. **Dogfood on `princi-ai`** — run the skill against the main app repo and review the generated `pr-best-practices.md`. (Already done; the file is checked into [princi-ai](https://github.com/princi-ai/princi-ai/blob/main/pr-best-practices.md) and referenced from `AGENTS.md` / `CLAUDE.md`.)
3. **Iterate on the reusability filter** based on the first 2–3 dogfood runs in other repos. Rules that consistently get flagged as "not useful" become exclusion examples in the synthesis prompt.
4. **Wire `/princi-review-pr` consumption** in a follow-up PR once this v1 stabilizes.

---

## Appendix A — sources consulted

- [Harish:Quang 2026-05-28 14:01 PDT](https://docs.google.com/document/d/1_euq5zD71PMp30lF_KKPvhre09YSOPyAHZNvYjCt9Dc/edit) — decision to move the PR best-practices work into the plugin repo.
- [Notes - Harish:Quang](https://docs.google.com/document/d/1rZYSkn061e-BbT3Ev0s7Jwb_N_eRluQI_5AqiL3AhCc/edit) — recurring list pinning "Submit PR for creating PR best practices [need to move to plugin] @harish"; also surfaces "PR history based best practices via GitHub Apps" and "get best practices from previous chats, GitHub, drive and others" as future scope.
- [Harish:Quang 2026-05-26 09:04 PDT](https://docs.google.com/document/d/19btyUVGViOleIMyMrKfy5dE06kxX2RDiP6cmu32raMY/edit) — individual-developer tool decision; consensus to build personal-context tooling rather than org-aware tooling.
- [Team sync 2026-05-25](https://docs.google.com/document/d/16UrZ_nWHwJOmqBP2qGi_-N5XmNH_nc3AQJBzLFeeVMM/edit) — origin of the "learn from historical PRs, design docs, bug reports" framing; "custom bugfinder" pattern that consumes a best-practices markdown file.
- [PR #487 review on princi-ai](https://github.com/princi-ai/princi-ai/pull/487) — concrete example of the kind of reusable review feedback this skill is designed to mine ("Can we add screenshot tests for these pages").
- [princi-plugin SKILL.md (PR #17 branch)](https://github.com/princi-ai/princi-plugin/blob/feat/princi-create-pr-best-practices/skills/princi-create-pr-best-practices/SKILL.md) — the source of truth for current implementation behavior.
