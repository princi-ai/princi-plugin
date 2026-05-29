# Changelog

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
