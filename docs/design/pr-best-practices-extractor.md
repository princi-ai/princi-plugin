# Engineering Design Doc: PR Best Practices Extractor

**Author:** TBD
**Status:** Draft
**Last updated:** 2026-05-29

---

## 1. Background and motivation

Our team's PR history is the highest-fidelity record of what we actually consider "good" code: which patterns survive review, which rollbacks taught us a lesson, and which mistakes show up repeatedly. That knowledge currently lives in reviewers' heads and in scattered comments.

We want to turn this implicit knowledge into an explicit, regularly-refreshed best-practices document that authors consult before opening a PR and reviewers consult before approving one.

## 2. Goals and non-goals

**Goals**

- Mine the team's recent closed PRs and synthesize concrete, actionable rules.
- Surface rules grounded in real incidents (rollbacks, follow-on fixes, repeated review comments) so they carry weight.
- Produce a single document short enough to skim before a code review.
- Refresh the document on a regular cadence so it tracks the team's evolving standards.

**Non-goals**

- Automated enforcement (linting, blocking merges).
- Posting comments on open PRs.
- Adjudicating style-vs-substance debates — the document surfaces patterns, humans decide.

## 3. Success metrics

| Metric                                  | Target                                                  |
| --------------------------------------- | ------------------------------------------------------- |
| PRs analyzed per run                    | ≥ 100 most recent closed                                |
| Rules accepted by team without manual edits | ≥ 80%                                                |
| Document length                         | Readable end-to-end before a single code review (~15 min) |
| Refresh cadence                         | Weekly or on-demand                                     |

## 4. System overview

```
GitHub API ──► PR Collector ──► Signal Extractor ──► Rule Synthesizer ──► pr-best-practices.md
                                       │
                                       └── Evidence store (PR refs, quoted comments)
```

Four logical stages:

1. **Collector** — fetches the last N closed PRs (default 100) with metadata, diffs, review comments, and commit messages.
2. **Signal extractor** — labels each PR with relevant signals: rollback, follow-on fix, contentious review, repeated comment theme, etc.
3. **Rule synthesizer** — clusters signals across PRs and drafts each rule with citations to source PRs.
4. **Writer** — emits a single Markdown document, grouped by topic.

## 5. Detailed design

### 5.1 Collector

- Uses the GitHub REST/GraphQL API with a fine-scoped PAT.
- Pulls the last 100 closed PRs in the configured repo(s).
- For each PR captures: title, body, files changed, review comments, review decisions, linked issues, merge state, and any subsequent PR that touches the same files within 7 days (candidate follow-on fix).
- Caches raw responses on disk so re-runs don't re-fetch.

### 5.2 Signal extractor

Each PR is tagged with zero or more signals:

- **Rollback** — PR title or commit message indicates revert.
- **Follow-on fix** — PR opened within 7 days touching ≥50% of the same files.
- **Heavy review** — > N inline comments or > 2 review rounds.
- **Repeated reviewer comment** — semantically similar comment seen across multiple PRs (clustered via embeddings).
- **Description quality** — has/missing test plan, summary, risk section.

Signals are deterministic where possible; LLM judgment is only used for the "repeated comment" clustering and for short-text classification (e.g., "is this comment a style nit or a correctness concern").

### 5.3 Rule synthesizer

For each cluster of related signals, an LLM prompt drafts a rule containing:

- A short imperative statement ("Quote untrusted GitHub strings before interpolating into shell commands").
- A 1-2 sentence rationale.
- Citations: PR numbers and quoted snippets from the source comments or commits.

The synthesizer is prompted to:

- Prefer specificity over generality (no "write good code" rules).
- Cite at least one concrete PR per rule.
- Group rules under topics: Security, Testing, Architecture, Migrations, Review etiquette, etc.

### 5.4 Output

A single `pr-best-practices.md` file at the repo root. Sections:

- Top of file: how to use the doc and date of last refresh.
- One section per topic.
- Each rule: rule statement → why it matters → evidence (PR links).
- Footer: PRs analyzed, signals found, rules that were dropped for low evidence.

## 6. Operational concerns

- **Trigger**: CLI command (`pr-bp extract`) and an optional weekly CI job.
- **Cost**: ~100 PRs × small LLM calls; bounded by signal cluster count, not raw PR count.
- **Secrets**: GitHub token via env var; no token logged or echoed.
- **Idempotency**: Output is reproducible given the same PR window and model snapshot.

## 7. Risks and mitigations

| Risk                                                 | Mitigation                                          |
| ---------------------------------------------------- | --------------------------------------------------- |
| LLM hallucinates rules without evidence              | Require ≥1 PR citation per rule; drop unsourced rules. |
| Document grows unbounded                             | Cap rule count per topic; force re-ranking on each run. |
| Stale rules outlive the practice that motivated them | Refresh fully each run; do not append.              |
| Privacy of reviewer comments                         | Quote only public PR content; redact author names on request. |

## 8. Rollout

1. Run against one repo, share output with team, collect edits.
2. Measure acceptance rate against the 80% target.
3. Tune signal extractor and synthesizer prompt based on rejected rules.
4. Schedule weekly refresh once acceptance threshold is met.

## 9. Open questions

- Do we want per-team or per-repo documents when a monorepo has multiple teams?
- Should the tool emit a diff against the previous version to make review easier?
- How do we handle rules that contradict each other across time (team standards evolved)?
