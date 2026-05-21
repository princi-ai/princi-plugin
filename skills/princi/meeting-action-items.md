# Meeting notes → action items

This section of the `/princi` skill handles converting meeting notes into a structured, timeline-aware action item list. The main `SKILL.md` dispatches here when the query is about meeting context (action items, decisions from a named or recent meeting).

---

## Step A: Timeline filter (apply before displaying results)

After retrieving results from `mcp__princi__search`, apply this filter:

### 1. Parse result dates
Extract the meeting date from each result — prefer the explicit meeting date in the document title or body over `modifiedTime`.

### 2. Recency-relative queries ("today's meeting", "latest", "recent", "this week")
- **Always fetch as much context as needed** — do not drop results solely because they are old.
- **Drop superseded instances:** if two results are from the same recurring meeting series (e.g. "weekly sync Apr 27" and "weekly sync May 6"), drop the older one — it is definitively superseded by the newer.
- **Warn when stale is certain:** if the only results available for the referenced meeting series are clearly not the latest instance (you can tell because a more recent meeting in that series was expected but is missing), surface a staleness notice. Do not silently present old context as current.
- If only one result exists for the series, use it as-is regardless of age.

### 3. Date-specific queries ("last Tuesday", "May 5th meeting")
- Target results from that specific date ±1 day; deprioritize all others.
- No staleness notice needed — the user specified the date intentionally.

### 4. Topic queries without a date ("what did we decide about auth")
- No recency filter; show dates prominently in the retrieved context display so the user can assess currency.

### Staleness notice format
Only show when context is known to be superseded (a newer instance of the same meeting series exists but was not retrieved, or the retrieved result is from a clearly earlier instance):

```
⚠️ Using [meeting name] from [date] — a more recent instance may exist.
   Try: /princi [broader or more recent meeting description]
```

Do not show this notice just because a result is old. Only show it when you have positive evidence the context is stale.

---

## Step B: Output format

After the timeline filter and the ambiguity check (SKILL.md Step 3.6), generate:

```markdown
---

## Meeting action items — [Meeting name] ([Date])
**Sources:** [N] results · [Drive / Gmail / Slack / Memory — list which contributed]

### Context:
**Background:** [1–3 sentences grounding the meeting in project history — what problem it addressed, what stage the project is in, who was involved. Enough context that someone unfamiliar can pick it up cold.]

**Key decisions:**
- [Decision — include any stated rationale or constraints]
- [Decision 2]

### Action items:
*Prioritize items assigned to or relevant to the current user; include others only if they directly affect the user's work. Ranked by priority — highest first. Use stated priority when available; otherwise infer from urgency, dependencies, and impact. Assign to the stated owner; use "TBD" if unowned.*

1. **[Owner]** [Task — enough detail to hand directly to a coding agent or planner]
   - Context: [1 sentence grounding this in the meeting discussion]
   - Source: [[doc title](url)]
2. **[Owner]** [Next task]
   - Context: ...
   - Source: ...

**Technical / operational constraints:** *(optional — only if explicitly mentioned)*
- [Stack, tool, or process constraint]

### Open questions / unresolved items:
*(Optional — only if explicitly deferred in the meeting)*
- [Deferred item]

### Assumptions made:
*(Only present if ambiguity existed — omit entirely if not needed)*
- [Assumption and why it was made]

---
*Retrieved by /princi from [N] sources · [today's date]*
```
