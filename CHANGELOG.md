# Changelog

## 0.1.12 — 2026-07-24

- **Codex support.** Add `.codex-plugin/plugin.json` and a Codex marketplace at `.agents/plugins/marketplace.json`, so `codex plugin marketplace add princi-ai/princi-plugin` → `/plugin install princi@princi-ai` installs the skills and MCP server together. The manifest points at the existing [`.mcp.json`](.mcp.json) — Codex's plugin loader reads the same `mcpServers` wrapper as Claude Code and strips the `type` field, so no Codex-specific server file is needed. MCP-only path documented as `codex mcp add princi --url …`
- **OpenCode support.** Add [`opencode/opencode.json`](opencode/opencode.json) — a `type: "remote"` MCP entry. OpenCode auto-starts OAuth on the server's `401`, and already discovers `SKILL.md` from `~/.claude/skills/`, so no skill duplication is needed
- **Antigravity support.** The repo root now doubles as an Antigravity plugin — [`plugin.json`](plugin.json) + [`mcp_config.json`](mcp_config.json) (using `serverUrl`; `url`/`httpUrl` are not supported) alongside the existing `skills/`, installable with `agy plugin install ./princi-plugin`. `plugin.json` carries only the documented `name` and `description` — Antigravity does not specify how unknown manifest fields are handled, so it deliberately omits `version`. Antigravity has no third-party marketplace yet, so local install is the only path
- CI: validate the Codex manifest's logo, and assert the MCP endpoint is byte-identical across all six client configs so one client can't silently drift onto a stale URL
- Bump version to 0.1.12 across all plugin manifests

## 0.1.11 — 2026-06-17

- Add `logo` to `.cursor-plugin` manifests so the Princi brand mark renders in Cursor's plugin tile
- Include `assets/` in release tarballs so `assets/logo.png` resolves in packaged plugin artifacts
- Bump version to 0.1.11 across all plugin manifests

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
