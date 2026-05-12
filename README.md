# Covy Plugin

Connect Covy — your personal context engine — to any AI coding tool.

Covy searches your emails, Drive docs, Slack messages, and meeting notes to bootstrap any AI task with the right background. Instead of manually copy-pasting context into your coding agent, type `/covy what do I need to do from today's meeting` and get grounded, ranked action items instantly.

**Examples:**
- `/covy what tasks do I have from today's Harish:Quang meeting?`
- `/covy what did we discuss about productionizing Covy in recent meetings?`
- `/covy create a plan to update the PRD based on our latest discussions`

---

## Get a Covy API Key

Contact the Princi team to get a `p_*` API key. *(Self-serve coming soon at princi.ai/settings/api-keys)*

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

**3. Set your API key** (add to `~/.zshrc` or `~/.bashrc`):

```bash
export COVY_API_KEY=p_your_key_here
```

**4. Restart Claude Code.** The `/covy` skill is ready.

---

## Setup: Claude Desktop

1. Download `covy.mcpb` from [Releases](https://github.com/princi-ai/covy-plugin/releases)
2. Double-click to install (or open via Claude Desktop → Extensions)
3. Enter your Covy API key when prompted
4. Restart Claude Desktop — Covy's tools are available in conversations

---

## Setup: Cursor

1. Open Cursor → Settings → MCP
2. Add a new MCP server with:
   - **URL:** `https://imyhlkntvqyznjdmzfjs.supabase.co/functions/v1/covy`
   - **Auth header:** `Authorization: Bearer p_your_key_here`
3. Save and restart Cursor

Or copy the config from [`cursor/mcp-config.json`](cursor/mcp-config.json) into your Cursor MCP settings.

---

## Setup: ChatGPT (Pro / Team / Enterprise)

1. Open ChatGPT → Settings → Developer Mode
2. Add MCP server URL: `https://imyhlkntvqyznjdmzfjs.supabase.co/functions/v1/covy`
3. Set auth header: `Authorization: Bearer p_your_key_here`
4. Covy's `search` and `fetch` tools are now available

---

## Troubleshooting

**`mcp__covy__search` not available:**
- Check that `COVY_API_KEY` is set: `echo $COVY_API_KEY`
- Restart your coding tool after setting the env var
- Verify your key is valid by contacting the Princi team

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

## Coming Soon

- cursor.directory one-click install
- Self-serve API key at princi.ai
- Gemini and OpenCode support
- OAuth self-serve (no API key needed)
