#!/usr/bin/env bash
#
# Every check CI runs, runnable locally before you push.
#
#   ./scripts/validate.sh                 # local: skip checks whose deps are missing
#   STRICT_DEPS=1 ./scripts/validate.sh   # CI: a missing dep is a failure
#
# Deliberately not `set -e`. Every check runs even after an earlier one fails,
# so a single run shows every problem rather than one per invocation.
#
# The `::error file=...::` lines are GitHub Actions annotations, which render on
# the PR diff. They are just noise-free text when run locally.

set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

STRICT_DEPS="${STRICT_DEPS:-0}"
failed=0
skipped=0

header() { printf '\n== %s\n' "$1"; }
pass()   { printf '   ok   %s\n' "$1"; }
fail()   { printf '   FAIL %s\n' "$1"; failed=$((failed + 1)); }

# A skip in CI means a dependency install broke. Treat it as a failure there,
# otherwise the job could go green having actually run nothing.
skip() {
  if [ "$STRICT_DEPS" = "1" ]; then
    printf '   FAIL %s (STRICT_DEPS=1 — dependency missing in CI)\n' "$1"
    failed=$((failed + 1))
  else
    printf '   skip %s\n' "$1"
    skipped=$((skipped + 1))
  fi
}

# ---------------------------------------------------------------- 1. JSON parse

header "JSON files parse"
json_bad=0
while IFS= read -r f; do
  if ! python3 -m json.tool "$f" >/dev/null 2>&1; then
    printf '::error file=%s::invalid JSON\n' "${f#./}"
    json_bad=1
  fi
done < <(find . -name '*.json' -not -path './node_modules/*' -not -path './.git/*')
if [ "$json_bad" -eq 0 ]; then pass "every *.json parses"; else fail "invalid JSON"; fi

# ---------------------------------------------------------------- 2. Plugin logo

# Logo lives under extensions["ai.princi"] in the portable Agent Plugins
# manifest. Claude Code rejects an unrecognized top-level logo field, so it is
# not duplicated into .claude-plugin/.
header "Plugin logo exists"
if python3 - <<'PY'
import json, os, sys

path = "plugin.json"
logo = json.load(open(path))["extensions"]["ai.princi"]["logo"]
# Relative-prefixed ("./assets/…") still resolves as a normal path.
if not os.path.isfile(logo):
    print(f"::error file={path}::logo path missing: {logo}")
    sys.exit(1)
print(f"   {path} -> {logo}")
PY
then pass "logo resolves"; else fail "logo missing"; fi

# ------------------------------------------------- 3. Agent Plugins conformance

# The repo root is an Agent Plugins 1.0.0 package: plugin.json + mcp.json +
# skills/. Validate both files against the canonical published schemas — spec
# §10.1 forbids reassigning a published schema identifier to different contents,
# so fetching by URL can never change meaning underneath us.
#
# Needs `jsonschema` and network access, so it is the one check that commonly
# cannot run on a laptop. CI installs the dependency and sets STRICT_DEPS=1.
header "Agent Plugins manifest and MCP config"
if ! python3 -c 'import jsonschema' 2>/dev/null; then
  skip "Agent Plugins schema — no jsonschema (pip install jsonschema)"
elif python3 - <<'PY'
import json, os, sys, urllib.request
from jsonschema import Draft202012Validator

SPEC = "1.0.0"
bad = False

# Both files must declare the same spec version (§10.1): a plugin.json /
# mcp.json version mismatch invalidates the MCP component on its own.
for path, kind in (("plugin.json", "plugin"), ("mcp.json", "mcp")):
    doc = json.load(open(path))
    expected = f"https://agent-plugins.org/schemas/{SPEC}/{kind}.schema.json"
    declared = doc.get("$schema")
    if declared != expected:
        print(f"::error file={path}::$schema is {declared!r}, expected {expected!r}")
        bad = True
        continue
    try:
        with urllib.request.urlopen(declared, timeout=30) as r:
            schema = json.load(r)
    except Exception as e:
        print(f"::error file={path}::could not fetch {declared}: {e}")
        bad = True
        continue
    errors = sorted(Draft202012Validator(schema).iter_errors(doc), key=lambda e: list(e.absolute_path))
    for e in errors:
        loc = "/".join(str(p) for p in e.absolute_path) or "<root>"
        print(f"::error file={path}::{loc}: {e.message}")
        bad = True
    if not errors:
        print(f"   {path} -> conforms to Agent Plugins {SPEC} {kind} schema")

# §6.1/§7.1: a skill is an immediate child of skills/ holding a SKILL.md regular
# file. Clients never recurse deeper, so a nested skill would be silently
# invisible rather than reported.
for entry in sorted(os.listdir("skills")):
    d = os.path.join("skills", entry)
    if not os.path.isdir(d):
        print(f"::error file=skills/{entry}::not a directory; skills/ holds only skill directories")
        bad = True
    elif not os.path.isfile(os.path.join(d, "SKILL.md")):
        print(f"::error file=skills/{entry}::no SKILL.md — this skill will not be discovered")
        bad = True
    else:
        print(f"   skills/{entry}/SKILL.md ok")

sys.exit(1 if bad else 0)
PY
then pass "conforms to Agent Plugins 1.0.0"; else fail "Agent Plugins conformance"; fi

# ------------------------------------------------------------ 4. MCP endpoint

# Every client config carrying the MCP endpoint must agree — a stale URL in one
# of them silently breaks that client only.
header "MCP endpoint identical across client configs"
if python3 - <<'PY'
import json, sys

EXPECTED = "https://princi.ai/mcp"
# file -> (json path to the server object, url key)
# mcp.json is the portable Agent Plugins config, read by Cursor and Codex.
# Claude Code does not implement the spec and needs its own copy, declared
# inline in its manifest rather than in a root .mcp.json.
# OpenCode is not a compatible client and nests its server under `mcp`,
# not `mcpServers`.
TARGETS = {
    "mcp.json":                    (["mcpServers", "princi"],  "url"),
    ".claude-plugin/plugin.json":  (["mcpServers", "princi"],  "url"),
    "opencode/opencode.json":      (["mcp", "princi"],         "url"),
}

bad = False
for path, (keys, url_key) in TARGETS.items():
    node = json.load(open(path))
    for k in keys:
        node = node[k]
    url = node[url_key]
    if url != EXPECTED:
        print(f"::error file={path}::{url_key} is {url!r}, expected {EXPECTED!r}")
        bad = True
    else:
        print(f"   {path} -> {url}")

# Claude Desktop passes the endpoint as an mcp-remote argv, not a url field.
desktop = json.load(open("desktop/manifest.json"))
args = desktop["server"]["mcp_config"]["args"]
if EXPECTED not in args:
    print(f"::error file=desktop/manifest.json::{EXPECTED} missing from mcp_config.args")
    bad = True
else:
    print(f"   desktop/manifest.json -> {EXPECTED}")

sys.exit(1 if bad else 0)
PY
then pass "all configs agree"; else fail "MCP endpoint drift"; fi

# --------------------------------------------------------- 5. Codex marketplace

# Codex's plugin manifest is gone — it loads the portable root package now — but
# its marketplace catalog is still client-owned, and distribution sits outside
# the portable spec. Guards the schema mistake caught in review on #34.
header "Codex marketplace schema"
if python3 - <<'PY'
import json, sys

bad = False

# MarketplacePluginAuthPolicy renames only these two; anything else fails the
# whole catalog parse with InvalidMarketplaceFile.
VALID_AUTH = {"ON_INSTALL", "ON_USE"}
VALID_INSTALL = {"INSTALLED_BY_DEFAULT", "AVAILABLE", "NOT_AVAILABLE"}
marketplace = ".agents/plugins/marketplace.json"
for entry in json.load(open(marketplace))["plugins"]:
    policy = entry["policy"]
    for key, valid in (("authentication", VALID_AUTH), ("installation", VALID_INSTALL)):
        value = policy[key]
        if value not in valid:
            print(f"::error file={marketplace}::{entry['name']}.policy.{key} is {value!r}, expected one of {sorted(valid)}")
            bad = True
        else:
            print(f"   {entry['name']}.policy.{key} = {value}")

sys.exit(1 if bad else 0)
PY
then pass "policy enums valid"; else fail "Codex marketplace schema"; fi

# ------------------------------------------------ 6. claude plugin validate

# The same validator the community-marketplace review pipeline runs on every
# submission. Needs no authentication.
#
# Both targets are needed: pointing it at the repo root resolves to
# marketplace.json, so the plugin manifest requires its own explicit invocation.
header "claude plugin validate --strict"
if ! command -v claude >/dev/null 2>&1; then
  skip "claude plugin validate — claude CLI not on PATH"
else
  claude_bad=0
  for target in . .claude-plugin/plugin.json; do
    if ! claude plugin validate "$target" --strict; then
      claude_bad=1
    fi
  done
  if [ "$claude_bad" -eq 0 ]; then
    pass "marketplace and plugin manifests validate"
  else
    fail "claude plugin validate"
  fi
fi

# ------------------------------------------------------------------- summary

printf '\n'
if [ "$failed" -gt 0 ]; then
  printf '%s check(s) FAILED' "$failed"
  [ "$skipped" -gt 0 ] && printf ', %s skipped' "$skipped"
  printf '\n'
  exit 1
fi

printf 'All checks passed'
[ "$skipped" -gt 0 ] && printf ' (%s skipped — run with STRICT_DEPS=1 to require them)' "$skipped"
printf '\n'
