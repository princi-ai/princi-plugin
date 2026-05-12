# Covy Plugin

Connect Covy — your personal context engine — to any AI coding tool.

Covy searches your emails, Drive docs, Slack messages, and meeting notes to bootstrap any AI task with the right background. Instead of manually copy-pasting context into your coding agent, type `/covy what do I need to do from today's meeting` and get grounded, ranked action items instantly.

**Examples:**
- `/covy what tasks do I have from today's Harish:Quang meeting?`
- `/covy what did we discuss about productionizing Covy in recent meetings?`
- `/covy create a plan to update the PRD based on our latest discussions`

---

## Setup: Claude Code (CLI / Co-work / IDE extension)

**1. Add the Princi marketplace** (one-time, in `~/.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "princi-ai": {
      "source": { "source": "github", "repo": "princi-ai/covy-plugin" }
    }
  }
}
```

**2. Install the plugin** in Claude Code:

```
/plugins install covy@princi-ai
```

**3. Use it.** The first time you invoke a Covy tool, the HTTP MCP client triggers OAuth auto-discovery and opens a browser to sign in to Princi. After sign-in the `/covy` skill is ready — no API key step.

---

## Setup: Claude Desktop

1. Download `covy.mcpb` from [Releases](https://github.com/princi-ai/covy-plugin/releases)
2. Double-click to install (or open via Claude Desktop → Extensions) — click Install
3. A browser opens to sign in to Princi
4. Done — Covy's tools are available in conversations

---

## Setup: Cursor

1. Open Cursor → Settings → MCP
2. Add a new MCP server with URL: `https://imyhlkntvqyznjdmzfjs.supabase.co/functions/v1/covy`
3. Save and restart Cursor

Auth uses OAuth auto-discovery when Cursor supports it. API-key fallback is available for older clients — contact Princi.

Or copy the config from [`cursor/mcp-config.json`](cursor/mcp-config.json) into your Cursor MCP settings.

---

## Setup: ChatGPT (Pro / Team / Enterprise)

1. Open ChatGPT → Settings → Developer Mode
2. Add MCP server URL: `https://imyhlkntvqyznjdmzfjs.supabase.co/functions/v1/covy`
3. Covy's `search` and `fetch` tools are now available

Auth uses OAuth auto-discovery when ChatGPT supports it. API-key fallback is available for older clients — contact Princi.

---

## Troubleshooting

**`mcp__covy__search` not available:**
- Re-run the OAuth sign-in flow: invoke a Covy tool — the HTTP MCP client should open a browser to sign in to Princi.
- Restart your coding tool if the sign-in browser doesn't open.

**Sign-in browser doesn't open:**
- Confirm your coding tool supports OAuth-enabled HTTP MCP servers (Claude Desktop, Claude Code).
- Check your terminal/console for an authorization URL printed by `mcp-remote` and open it manually.

**Token expired / 401 errors:**
- Sign out by clearing the local `mcp-remote` token cache at `~/.mcp-auth/` and re-invoke a Covy tool to trigger a fresh sign-in.

**0 results from `/covy`:**
- Try a broader or rephrased query
- Ensure your Google/Slack accounts are connected in Princi

---

## Updating

```
/plugins update covy@princi-ai
```

---

## Verify a Release

Each release ships a `covy-<version>-checksums.txt` file with SHA256 hashes for every artifact. After downloading, verify with:

```bash
sha256sum -c covy-v0.1.0-checksums.txt
```

---

## Privacy Policy

**Data collected.** Covy receives an OAuth identity (your Supabase Auth subject) and the MCP tool invocations you make against the Covy server — search queries and the IDs you fetch.

**Use.** This data is used solely to authenticate you and to return search/fetch results from your indexed sources (Gmail, Drive, Slack, Calendar, memory).

**Storage.** OAuth tokens are encrypted at rest in Supabase. Your indexed corpora are stored per-user.

**Third-party sharing.** None beyond the user's own connected providers (e.g., Google, Slack) that you have explicitly authorized.

**Retention.** Data is retained for the lifetime of your account and is revocable at any time via princi.ai.

**Contact.** Reach us at `support@princi.ai` for any privacy questions or data deletion requests.

Full policy: https://princi.ai/privacy

---

## Coming Soon

- cursor.directory one-click install
- Gemini and OpenCode support
