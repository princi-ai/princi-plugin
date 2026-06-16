# Changelog

## 0.1.10 — 2026-06-16

- Rename `/princi-review-pr` → **`/princi-code-review`** (across the plugin and the app UI) for product-consistent naming
- Rename `/princi-create-pr-best-practices` → **`/princi-update-pr-best-practices`**; the skill now **bootstraps** when no `.princi/pr-best-practices.md` exists and does an **incremental merge** otherwise — synthesizing only PRs closed since the recorded `generated_at` and merging them in (collector gains a `--since YYYY-MM-DD` flag)
- The generated `.princi/pr-best-practices.md` now carries YAML frontmatter (`generated_at`, `repository`, `prs_analyzed`, `rules`) as the machine-readable source of truth for staleness + the next incremental window
- `/princi-code-review` now **auto-refreshes** the best-practices file before reviewing — generating it if absent or older than 2 weeks, in a separate sub-agent so the PR-history analysis stays out of the review's context
- Bump version to 0.1.10 across all plugin manifests (incl. `desktop/manifest.json`, which was lagging at 0.1.8)

## 0.1.9 — 2026-06-05

- `/princi-review-pr`: add a **suppression gate** to Step 6 so findings already declined-with-reason in a PR's review comments (the prior-decisions ledger) are never re-raised — fixes the repeated "stranded users" style noise where a concern the author already answered keeps coming back; output gains an "Already addressed" section listing what was deduped
- Align `.cursor-plugin` manifests to the current version (were lagging at 0.1.7)
- Bump version to 0.1.9 across all plugin manifests

## 0.1.8 — 2026-06-01

- Add plugin logo: ship `assets/logo.png` and reference it via `logo` field in `.claude-plugin/plugin.json` and the marketplace entry so Cursor's plugin tile renders the Princi brand mark instead of the default placeholder
- Add `displayName: "Princi"` to both manifests for capitalized rendering in plugin pickers
- Bump version to 0.1.8 across all plugin manifests

## 0.1.7 — 2026-05-29

- Point MCP endpoints at `api.princi.ai` custom domain instead of the Supabase project URL
- Bump version to 0.1.7 across all plugin manifests

## 0.1.6 — 2026-05-28

- Add `/princi-create-pr-best-practices` skill: analyze closed GitHub PRs, extract reusable team conventions, and write `.princi/pr-best-practices.md`
- Include `collect-pr-evidence.mjs` collector script for deterministic PR evidence gathering via `gh`
- Bump version to 0.1.6 across all plugin manifests

## 0.1.5 — 2026-05-28

- Add `eng-design-doc` sub-skill to `/princi`: create or update an engineering design doc grounded in Drive/Slack/Gmail context and best-practices files; detects conflicts between the doc and recent discussions, fills best-practice gaps, writes the doc (local `.md` + PR preferred, Google Doc with permission gate, brand-new docs with a dedup check)
- Extract `untrusted-data.md` shared include — the prompt-injection defense now lives in one canonical place, referenced by `SKILL.md` and all sub-skills
- Restructure `SKILL.md` Step 3.5b into an ordered routing table (eng-design-doc → meeting-action-items → fall-through)
- Bump `desktop/manifest.json` from 0.1.0 to 0.1.5 to bring all manifests in sync
- Bump version to 0.1.5 across all plugin manifests

## 0.1.4 — 2026-05-26

- Add `/princi-review-pr` skill: personal PR review grounded in Drive docs, past coding-agent chats, and PR history via Princi context
- Automatic best-practices extraction: recurring patterns (≥2 PRs) are promoted to `pr-best-practices.md` for team sharing
- Bump version to 0.1.4 across all plugin manifests

## 0.1.0 — 2026-05-12

Initial release.

- `/princi` skill for Claude Code (CLI, Co-work, IDE extension)
- Meeting notes → action items workflow
- Claude Desktop Extension manifest
- Cursor MCP config reference
- ChatGPT Dev Mode setup guide
