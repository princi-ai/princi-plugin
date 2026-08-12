# Changelog

## 0.1.14 — 2026-08-11

- **Clean `claude plugin validate --strict`, in preparation for submitting to the [`claude-community`](https://github.com/anthropics/claude-plugins-community) marketplace.** The review pipeline runs the same validator on every submission. Three warnings came from fields Claude Code does not recognize and silently ignores: `id` in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json), and `logo` in both `.claude-plugin/` manifests. The logo is unaffected in the clients that actually render it — Cursor's tile reads [`.cursor-plugin/marketplace.json`](.cursor-plugin/marketplace.json) and the portable package carries it under `extensions["ai.princi"]` in [`plugin.json`](plugin.json). The fourth warning was a missing marketplace-level `description`, now written
- CI: the logo-existence check hardcoded the two `.claude-plugin/` manifests and would have thrown `KeyError` once the field was gone. It now checks the two manifests that carry a logo, including the portable package's `extensions["ai.princi"].logo`, which was never covered before
- **Document the plugin's OAuth scopes.** The MCP server requests `openid`, `profile`, and `email` — identity only, no provider scopes. Gmail, Drive, Slack, and Calendar are connected separately in the Princi app under their own consent screen, so installing the plugin grants no source access on its own. The README now states this and shows the `curl` against the server's RFC 9728 metadata that proves it, rather than asking the reader to take it on faith
- **Fix the skill names in the README.** Plugin-loaded skills are namespaced by plugin name, so the invocations are `/princi:princi`, `/princi:princi-code-review`, and `/princi:princi-update-pr-best-practices`. Every example was written unprefixed and would not have worked as typed. The manual-copy path (OpenCode) has no prefix and is called out separately
- **Delete `.mcp.json`; declare the MCP server inline in [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json) instead.** Claude Code reads a plugin's MCP config from either a root `.mcp.json` or an inline `mcpServers` object in the manifest, so the separate file was never required. The server key stays `princi`, so nothing about the runtime changes: tools remain `mcp__plugin_princi_princi__search` / `__fetch` and the server still registers as `plugin:princi:princi`. Verified three ways — the docs, `claude plugin validate` (which rejects a nested `mcpServers` wrapper as `Invalid input` and accepts the flat server map), and a probe plugin whose stdio command wrote a marker file when Claude Code started it from an inline declaration
- A side effect worth having: the root `.mcp.json` also acted as *project-scoped* config, so anyone with this repo open in Claude Code got a second `princi` server alongside the one from their installed plugin. That duplicate is gone, and with it the need for a local `.claude/settings.local.json` carrying `disabledMcpjsonServers: ["princi"]` to suppress it
- CI: the MCP endpoint parity check reads the inline block instead of `.mcp.json`, and both release workflows drop the deleted file from the tarball
- **Fix the Claude Code install instructions.** The README documented only the `extraKnownMarketplaces` route and told you to run `/plugins install princi@princi-ai`. That suffix is correct only for that route, because the JSON key names the marketplace. Anyone who added it the documented way — `/plugin marketplace add princi-ai/princi-plugin` — takes the name from this repo's `marketplace.json` instead and needs `princi@princi-plugin`, so the copy-pasted command failed with "plugin not found." The slash-command route now leads, `settings.json` is a documented alternative, and the reason the two ids differ is spelled out. Also `/plugins install` → `/plugin install`
- Document the marketplace-free install: cloning into `~/.claude/skills/princi/` loads the plugin as `princi@skills-dir` with no install step, at the cost of updates and version pinning
- Bump version to 0.1.14 across all plugin manifests

## 0.1.13 — 2026-08-10

- **Agent Plugins 1.0.0 conformance.** The repo root is now a portable [Agent Plugins](https://agent-plugins.org) package, so any spec-aware client can install Princi without a vendor-specific path. [`plugin.json`](plugin.json) becomes the portable manifest — it gains the required `$schema`, plus `version`, `author`, `homepage`, `repository`, `license`, and `keywords`. The manifest schema is closed, so presentation metadata (logo, display name, category) moves under an `ai.princi` reverse-domain key in `extensions`
- Add [`mcp.json`](mcp.json) — the spec's fixed MCP location, declaring the Princi server as `streamable-http`. This is a separate file from Claude Code's `.mcp.json`, which keeps its own `http` type; the two are kept in sync by CI
- `skills/` already matched the spec's discovery contract (immediate children holding a `SKILL.md`), so no skills moved
- **Delete the Cursor and Codex plugin manifests.** Both are [compatible clients](https://agent-plugins.org/compatible-clients), so they load the portable root package directly — `.cursor-plugin/plugin.json` and the whole `.codex-plugin/` directory are gone. Each client's marketplace catalog stays (`.cursor-plugin/marketplace.json`, `.agents/plugins/marketplace.json`): distribution, install policy, and signing are explicitly outside the portable spec. Note that Codex's plugin browser loses the `interface` block's `longDescription` and `defaultPrompt`, which have no portable equivalent
- **Claude Code stays on its own path.** It is not a compatible client, so `.claude-plugin/` and `.mcp.json` are unchanged and remain the source of truth for its install and release flow
- **OpenCode stays supported** via [`opencode/opencode.json`](opencode/opencode.json). It is not on the compatible-clients list (that entry is OpenClaw, a different product) and has no plugin format that can register MCP servers or skills, so it keeps its own `type: "remote"` MCP config plus a manual skill copy
- **Drop Antigravity support** — remove `mcp_config.json`. This also frees the root `plugin.json`, which Antigravity shared: it had deliberately carried only `name` and `description`, a constraint incompatible with the `$schema` the spec requires
- Remove `cursor/mcp-config.json`; Cursor MCP-only setup is documented inline in the README
- Point all client MCP endpoints at `https://princi.ai/mcp` instead of `https://api.princi.ai/functions/v1/princi`. The public facade serves RFC 9728 discovery from the MCP host origin, so clients that re-discover OAuth metadata after the browser callback (Cursor Cloud Agents) no longer fail token exchange. `api.princi.ai` remains the upstream and keeps working for already-installed clients
- CI: validate `plugin.json` and `mcp.json` against the canonical published schemas (spec §10.1 makes those identifiers immutable), assert both declare the same spec version, and check every `skills/` child is discoverable
- Bump version to 0.1.13 across all plugin manifests

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
