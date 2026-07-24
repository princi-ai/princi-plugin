# Princi Plugin

Connect Princi — your personal context engine — to any AI coding tool.

Princi searches your emails, Drive docs, Slack messages, and meeting notes to bootstrap any AI task with the right background. Instead of manually copy-pasting context into your coding agent, type `/princi what do I need to do from today's meeting` and get grounded, ranked action items instantly.

**Examples:**
- `/princi what tasks do I have from today's team sync meeting?`
- `/princi what did we discuss about productionizing Princi in recent meetings?`
- `/princi create a plan to update the PRD based on our latest discussions`

---

## Setup: Claude Code (CLI / Co-work / IDE extension)

**1. Add the Princi marketplace** (one-time, in `~/.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "princi-ai": {
      "source": { "source": "github", "repo": "princi-ai/princi-plugin" }
    }
  }
}
```

**2. Install the plugin** in Claude Code:

```
/plugins install princi@princi-ai
```

**3. Use it.** The first time you invoke a Princi tool, the HTTP MCP client triggers OAuth auto-discovery and opens a browser to sign in to Princi. After sign-in the `/princi` skill is ready — no API key step.

---

## Setup: Claude Desktop

1. Download `princi.mcpb` from [Releases](https://github.com/princi-ai/princi-plugin/releases)
2. Double-click to install (or open via Claude Desktop → Extensions) — click Install
3. A browser opens to sign in to Princi
4. Done — Princi's tools are available in conversations

---

## Setup: Cursor

**Option A — Install as a Cursor plugin** (bundles the skill + MCP server):

In Cursor, run `/add-plugin princi` — or browse [cursor.com/marketplace](https://cursor.com/marketplace) and install Princi from the listing.

Cursor registers the Princi MCP server and `/princi` skill automatically from [.cursor-plugin/plugin.json](.cursor-plugin/plugin.json). The first time you invoke a Princi tool, an OAuth browser flow opens to sign in to Princi.

**Option B — MCP server only** (no plugin):

1. Open Cursor → Settings → MCP
2. Add a new MCP server with URL: `https://api.princi.ai/functions/v1/princi`
3. Save and restart Cursor

Or copy the config from [cursor/mcp-config.json](cursor/mcp-config.json) into your Cursor MCP settings.

Auth uses OAuth auto-discovery when Cursor supports it. API-key fallback is available for older clients — contact Princi.

---

## Setup: Codex (CLI / desktop app)

**Option A — Install as a Codex plugin** (bundles the skills + MCP server):

```
codex plugin marketplace add princi-ai/princi-plugin
```

Then, inside Codex:

```
/plugin install princi@princi-ai
/reload-plugins
```

Or browse with `/plugins`. Codex registers the Princi MCP server from [codex/mcp.json](codex/mcp.json) and the `/princi` skills from [skills/](skills/). The first time you invoke a Princi tool, an OAuth browser flow opens to sign in.

> Plugins are supported in the Codex CLI and desktop app. They are **not** available in ChatGPT Chat, the IDE extension, or mobile — use Option B there.

**Option B — MCP server only** (no plugin):

```
codex mcp add princi --url https://api.princi.ai/functions/v1/princi
codex mcp login princi
```

`codex mcp add` probes the server for OAuth metadata and starts the sign-in flow. Equivalent manual config in `~/.codex/config.toml`:

```toml
[mcp_servers.princi]
url = "https://api.princi.ai/functions/v1/princi"
```

If your network requires a fixed OAuth callback port, add a top-level `mcp_oauth_callback_port = 5555` to the same file.

---

## Setup: ChatGPT (Pro / Team / Enterprise)

1. Open ChatGPT → Settings → Developer Mode
2. Add MCP server URL: `https://api.princi.ai/functions/v1/princi`
3. Princi's `search` and `fetch` tools are now available

Auth uses OAuth auto-discovery when ChatGPT supports it. API-key fallback is available for older clients — contact Princi.

---

## Setup: OpenCode

Add Princi to your OpenCode config — `~/.config/opencode/opencode.json` for all projects, or `opencode.json` in a project root:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "princi": {
      "type": "remote",
      "url": "https://api.princi.ai/functions/v1/princi",
      "enabled": true
    }
  }
}
```

Or copy [opencode/opencode.json](opencode/opencode.json).

OpenCode detects the server's `401` response and starts the OAuth flow automatically the first time you invoke a Princi tool. To trigger it up front, run `opencode mcp auth princi` (and `opencode mcp logout princi` to sign out).

**Skills.** OpenCode reads `SKILL.md` from `~/.claude/skills/` and `~/.agents/skills/` as well as its own `~/.config/opencode/skills/` — so if you already installed the Princi plugin in Claude Code, `/princi` works in OpenCode with no extra step. Otherwise, copy [skills/](skills/) into `~/.config/opencode/skills/`.

OpenCode plugins cannot register MCP servers or skills, so there is no plugin bundle to install — the config above is the whole setup.

---

## Setup: Antigravity

**Option A — MCP server only** (fastest):

Type `/mcp` in the prompt panel to open the MCP manager, or edit the raw config directly — `~/.gemini/config/mcp_config.json` globally, or `.agents/mcp_config.json` for a single workspace:

```json
{
  "mcpServers": {
    "princi": {
      "serverUrl": "https://api.princi.ai/functions/v1/princi"
    }
  }
}
```

Antigravity reloads MCP config on save. The first Princi tool call opens an OAuth browser flow.

> `serverUrl` is the current key for Streamable HTTP servers — the older `url` / `httpUrl` fields are deprecated.

**Option B — Install as an Antigravity plugin** (bundles the skills + MCP server):

```bash
git clone https://github.com/princi-ai/princi-plugin
agy plugin install ./princi-plugin
```

Or copy the repo into `~/.gemini/config/plugins/` (all workspaces) or `.agents/plugins/` (one workspace). The repo root doubles as an Antigravity plugin — [plugin.json](plugin.json), [mcp_config.json](mcp_config.json), and [skills/](skills/).

Antigravity has no third-party plugin marketplace yet, so local install is the only path today.

---

## Troubleshooting

**`mcp__princi__search` not available:**
- Re-run the OAuth sign-in flow: invoke a Princi tool — the HTTP MCP client should open a browser to sign in to Princi.
- Restart your coding tool if the sign-in browser doesn't open.

**Sign-in browser doesn't open:**
- Confirm your coding tool supports OAuth-enabled HTTP MCP servers (Claude Desktop, Claude Code, Codex, Cursor, OpenCode, Antigravity).
- In Codex, force the flow with `codex mcp login princi`; in OpenCode, `opencode mcp auth princi`.
- Check your terminal/console for an authorization URL printed by `mcp-remote` and open it manually.

**Token expired / 401 errors:**
- Sign out by clearing the local `mcp-remote` token cache at `~/.mcp-auth/` and re-invoke a Princi tool to trigger a fresh sign-in.

**0 results from `/princi`:**
- Try a broader or rephrased query
- Ensure your Google/Slack accounts are connected in Princi

---

## Updating

```
/plugins update princi@princi-ai
```

---

## Verify a Release

Each release ships a `princi-<version>-checksums.txt` file with SHA256 hashes for every artifact. After downloading, verify with:

```bash
sha256sum -c princi-v0.1.0-checksums.txt
```

---

## Privacy Policy

**Data collected.** Princi receives an OAuth identity (your Supabase Auth subject) and the MCP tool invocations you make against the Princi server — search queries and the IDs you fetch.

**Use.** This data is used solely to authenticate you and to return search/fetch results from your indexed sources (Gmail, Drive, Slack, Calendar, memory).

**Storage.** OAuth tokens are encrypted at rest in Supabase. Your indexed corpora are stored per-user.

**Third-party sharing.** None beyond the user's own connected providers (e.g., Google, Slack) that you have explicitly authorized.

**Retention.** Data is retained for the lifetime of your account and is revocable at any time via princi.ai.

**Contact.** Reach us at `support@princi.ai` for any privacy questions or data deletion requests.

Full policy: https://princi.ai/privacy

---

## Coming Soon

- cursor.directory one-click install
- Antigravity plugin marketplace listing (once Google ships third-party distribution)
- Gemini CLI support
