# Princi Plugin

Connect Princi — your personal context engine — to any AI coding tool.

Princi searches your emails, Drive docs, Slack messages, and meeting notes to bootstrap any AI task with the right background. Instead of manually copy-pasting context into your coding agent, type `/princi:princi what do I need to do from today's meeting` and get grounded, ranked action items instantly.

**Examples:**
- `/princi:princi what tasks do I have from today's team sync meeting?`
- `/princi:princi what did we discuss about productionizing Princi in recent meetings?`
- `/princi:princi create a plan to update the PRD based on our latest discussions`

> Plugin-installed skills are namespaced: `/princi:princi`, `/princi:princi-code-review`, `/princi:princi-update-pr-best-practices`. Copying `skills/` in by hand (the OpenCode path) drops the prefix.

---

## Setup: Claude Code (CLI / Co-work / IDE extension)

Run both inside Claude Code:

```
/plugin marketplace add princi-ai/princi-plugin
/plugin install princi@princi-plugin
```

The first Princi tool call opens a browser to sign in. After that, `/princi:princi` is ready — no API key step.

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

Cursor reads the [Agent Plugins](https://agent-plugins.org) package at the repo root — [plugin.json](plugin.json), [mcp.json](mcp.json), and [skills/](skills/) — and registers the Princi MCP server and the Princi skills automatically. The first time you invoke a Princi tool, an OAuth browser flow opens to sign in to Princi.

**Option B — MCP server only** (no plugin):

1. Open Cursor → Settings → MCP
2. Add a new MCP server with URL: `https://princi.ai/mcp`
3. Save and restart Cursor

Or paste this into your Cursor MCP settings:

```json
{
  "mcpServers": {
    "princi": {
      "type": "http",
      "url": "https://princi.ai/mcp"
    }
  }
}
```

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

Or browse with `/plugins`. Codex reads the [Agent Plugins](https://agent-plugins.org) package at the repo root — [plugin.json](plugin.json), [mcp.json](mcp.json), and [skills/](skills/). The first time you invoke a Princi tool, an OAuth browser flow opens to sign in.

> Plugins are supported in the Codex CLI and desktop app. They are **not** available in ChatGPT Chat, the IDE extension, or mobile — use Option B there.

---

## Setup: ChatGPT (Pro / Team / Enterprise)

1. Open ChatGPT → Settings → Developer Mode
2. Add MCP server URL: `https://princi.ai/mcp`
3. Princi's `search` and `fetch` tools are now available

Auth uses OAuth auto-discovery when ChatGPT supports it. API-key fallback is available for older clients — contact Princi.

---

## Setup: OpenCode

OpenCode is not an [Agent Plugins client](https://agent-plugins.org/compatible-clients), so it needs its own MCP config and a manual skill copy.

**Add MCP server.** Add Princi MCP to your OpenCode config — `~/.config/opencode/opencode.json` for all projects, or `opencode.json` in a project root:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "princi": {
      "type": "remote",
      "url": "https://princi.ai/mcp",
      "enabled": true
    }
  }
}
```

Or copy [opencode/opencode.json](opencode/opencode.json).

OpenCode detects the server's `401` response and starts the OAuth flow automatically the first time you invoke a Princi tool. To trigger it up front, run `opencode mcp auth princi` (and `opencode mcp logout princi` to sign out).

**Skills.** Install the Princi skills into OpenCode's own skills directory — copy the [skills/](skills/) folders into `~/.config/opencode/skills/` so each skill lands at `~/.config/opencode/skills/<name>/SKILL.md`:

```bash
git clone https://github.com/princi-ai/princi-plugin
cd princi-plugin
mkdir -p ~/.config/opencode/skills
cp -R skills/princi skills/princi-code-review skills/princi-update-pr-best-practices ~/.config/opencode/skills/
```

Then `/princi`, `/princi-code-review`, and `/princi-update-pr-best-practices` are available in OpenCode. (OpenCode can also discover `SKILL.md` from `~/.claude/skills/`, but only on builds after the late-Dec-2025 fix — installing into `~/.config/opencode/skills/` works on every version.)

OpenCode plugins cannot register MCP servers or skills, so there is no plugin bundle to install — the MCP config above plus these skills are the whole setup.

---

## Setup: any Agent Plugins client

The repo root is a conformant [Agent Plugins 1.0.0](https://agent-plugins.org) package, so any [compatible client](https://agent-plugins.org/compatible-clients) — VS Code, Cursor, GitHub Copilot, Codex, Kiro, Hermes Agent, OpenClaw — can install Princi without a vendor-specific path:

```bash
git clone https://github.com/princi-ai/princi-plugin
```

Then point your client at the clone. It reads three fixed locations from the plugin root — no configuration, no discovery indirection:

| Location | Contents |
| --- | --- |
| [`plugin.json`](plugin.json) | Portable manifest — identity, version, and metadata |
| [`mcp.json`](mcp.json) | The Princi MCP server, as a `streamable-http` entry |
| [`skills/`](skills/) | `princi`, `princi-code-review`, `princi-update-pr-best-practices` |

The first Princi tool call opens an OAuth browser flow to sign in.

### What's left outside the portable package

Cursor and Codex are both [compatible clients](https://agent-plugins.org/compatible-clients), so they load skills and MCP from the root package and no longer need a vendor-specific plugin manifest (`.cursor-plugin/plugin.json`, `.codex-plugin/`). Cursor can publish from that root package alone. Codex still needs a marketplace catalog for `codex plugin marketplace add` / install. What remains outside the portable package is only what the spec deliberately leaves out:

| File | Why it can't be portable |
| --- | --- |
| `.claude-plugin/plugin.json` | Claude Code is not a compatible client, so it needs its own manifest. The MCP server is declared inline in it |
| `.claude-plugin/marketplace.json` | Marketplace catalog — distribution is outside the spec |
| `.agents/plugins/marketplace.json` | Codex's marketplace catalog |
| `desktop/manifest.json` | Claude Desktop takes an `.mcpb` bundle, not a plugin |
| `opencode/opencode.json` | OpenCode is not a compatible client and has no plugin format for MCP servers or skills |

The spec's portable surface is just skills and MCP servers. Marketplace catalogs, install policy, and signing are explicitly out of scope, so each stays in its platform's own file.

One caveat on `extensions`: Princi's presentation metadata (logo, display name, category) sits under an `ai.princi` namespace in `plugin.json` because the manifest schema is closed and non-portable fields have nowhere else to go. No client implements that namespace, so it is documentation, not behavior — the spec is explicit that an extension "is not a way for a plugin author to make up fields that existing clients will automatically understand."

CI validates `plugin.json` and `mcp.json` against the canonical published schemas on every PR, and asserts every MCP config points at the same endpoint.

---

## Troubleshooting

**`mcp__princi__search` not available:**
- Re-run the OAuth sign-in flow: invoke a Princi tool — the HTTP MCP client should open a browser to sign in to Princi.
- Restart your coding tool if the sign-in browser doesn't open.

**Sign-in browser doesn't open:**
- Confirm your coding tool supports OAuth-enabled HTTP MCP servers (Claude Desktop, Claude Code, Codex, Cursor, OpenCode).
- In Codex, force the flow with `codex mcp login princi`; in OpenCode, `opencode mcp auth princi`.
- Check your terminal/console for an authorization URL printed by `mcp-remote` and open it manually.

**Token expired / 401 errors:**
- Sign out by clearing the local `mcp-remote` token cache at `~/.mcp-auth/` and re-invoke a Princi tool to trigger a fresh sign-in.

**0 results from `/princi:princi`:**
- Try a broader or rephrased query
- Ensure your Google/Slack accounts are connected in Princi

---

## Updating

```
/plugin update princi@princi-plugin
```

In Codex, the id is `princi@princi-ai`.

---

## Verify a Release

Each release ships a `princi-<version>-checksums.txt` file with SHA256 hashes for every artifact. After downloading, verify with:

```bash
sha256sum -c princi-v0.1.0-checksums.txt
```

---

## What the plugin can access

Installing this plugin grants **identity only** — the MCP server requests `openid`, `profile`, and `email`. No Gmail, Drive, Slack, or Calendar scope. Verify against the server's public metadata:

```bash
curl -s https://princi.ai/.well-known/oauth-protected-resource
# "scopes_supported": ["openid", "profile", "email"]
```

Sources are connected separately in the Princi app at [princi.ai](https://princi.ai), under their own consent screen. Those grants belong to your account, not this plugin, so uninstalling does not disconnect them — revoke them in the app.

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
- Claude Code support for the Agent Plugins spec, which would let `.claude-plugin/` go away
