---
name: error-analysis
description: Analyse agent errors to find tool misuse, missing infrastructure, and documentation gaps
user-invocable: true
---

# /error-analysis — Agent Error Analysis

**Usage:** `/error-analysis [--since <date>] [--tool <name>]`

Scans Claude Code transcript files for tool errors, stores them in `config_db.agent_errors`, then produces an actionable diagnosis across three dimensions:

1. **Tool misuse** — Are agents calling tools with wrong arguments, bad flags, or incorrect assumptions?
2. **Missing infrastructure** — Are agents trying to use tools/commands/modules that don't exist in our environment?
3. **Documentation gaps** — Should CLAUDE.md files, skills, or memory be updated to prevent recurring errors?

## Arguments

| Arg | Default | Description |
|-----|---------|-------------|
| `--since` | 7 days | Only analyse errors after this date (ISO or relative like `3d`, `1w`) |
| `--tool` | all | Filter to a specific tool name (e.g. `Bash`, `mcp__portainer__*`) |

---

## Step 0: Scan Transcripts (ALWAYS DO THIS FIRST)

Run the transcript scanner to ingest any new errors since the last scan:

```bash
node /home/coder/.claude/hooks/scan-errors.js --since 168
```

This reads JSONL transcript files from `/home/coder/.claude/projects/-websites/`, finds `tool_result` blocks with `is_error: true`, correlates them with their `tool_use` blocks, and inserts new errors into `config_db.agent_errors`. It tracks scan state to avoid duplicates.

Adjust `--since` hours to match the `--since` argument (7 days = 168 hours, 3 days = 72 hours).

---

## Step 1: Fetch Errors

Only fetch **unresolved** errors (where `resolved_at IS NULL`):

```bash
PGPASSWORD=lKdOazfzXVliL0YKBM5ddJ8gTPrpkraL psql -h 192.168.0.20 -p 5439 -U urd -d config_db -t -A -c "
  SELECT json_agg(e ORDER BY e.created_at DESC)
  FROM agent_errors e
  WHERE resolved_at IS NULL
    AND created_at > NOW() - INTERVAL '7 days'
"
```

Adjust the interval if `--since` is provided. Add `AND tool_name LIKE '...'` if `--tool` is provided.

If zero rows returned, report "No unresolved errors in the selected period" and stop.

---

## Step 2: Classify Each Error

For every error, determine its **category**:

### Category A: Tool Misuse
The tool exists and works, but the agent used it incorrectly.

Signals:
- Wrong arguments or flags (e.g. `git log -uall`, `psql` with bad syntax)
- Calling a tool for something it can't do (e.g. using `Read` on a directory)
- Incorrect assumptions about output format
- Using a Bash command instead of a dedicated tool

### Category B: Missing Infrastructure
The agent tried to use something that doesn't exist in our environment.

Signals:
- `command not found` errors
- Missing npm modules (`Cannot find module`)
- Missing binaries or system tools
- MCP tools returning "not found" or connection errors
- Database tables/columns that don't exist

### Category C: Documentation Gap
The error could have been prevented if the agent had better instructions.

Signals:
- Repeated errors of the same type across sessions
- Agent trying a reasonable approach that happens to be wrong for our setup
- Assumptions that contradict our conventions (port numbers, paths, naming)
- Missing environment variables or credentials

An error can belong to multiple categories.

---

## Step 3: Pattern Detection

Group errors to find systemic issues:

1. **Frequency** — Same error pattern appearing 3+ times? That's a systemic issue, not a one-off.
2. **Tool hotspots** — Which tools generate the most errors? Rank by count.
3. **Session clustering** — Many errors in one session may indicate a bad approach rather than individual tool issues.
4. **Temporal patterns** — Errors spiking after a config change or deployment?

---

## Step 4: Generate Recommendations

For each pattern found, produce a concrete recommendation:

### For Tool Misuse
- Specify the correct usage
- Suggest adding the correction to the relevant CLAUDE.md or memory file
- Example: "Agents keep using `psql -c` with unescaped JSON. Add a note to yggdrasil CLAUDE.md recommending dollar-quoting for JSON values."

### For Missing Infrastructure
- Identify what's missing
- Recommend whether to install it, document its absence, or suggest an alternative
- Example: "`yq` is not installed in the container. Either add it to the Dockerfile or document using `python3 -c 'import yaml'` as alternative."

### For Documentation Gaps
- Identify which file should be updated (CLAUDE.md, memory, skill)
- Draft the specific text to add
- Example: "Add to mimir CLAUDE.md: 'Database password is in /home/coder/.claude/.env, not in the container environment.'"

---

## Step 5: Output Report

```markdown
## Agent Error Analysis — {date range}

**Errors analysed:** {count}
**Period:** {start} to {end}

### Summary

| Category | Count | Action Needed |
|----------|-------|---------------|
| Tool Misuse | {n} | {brief} |
| Missing Infrastructure | {n} | {brief} |
| Documentation Gap | {n} | {brief} |

### Tool Hotspots

| Tool | Errors | Top Error |
|------|--------|-----------|
| {tool} | {n} | {most common error summary} |

### Findings

#### 1. {Finding title}
**Category:** {A/B/C}
**Occurrences:** {n}
**Error:** {representative error_summary}
**Root cause:** {analysis}
**Recommendation:** {specific action}
**Fix location:** {file path to update}

#### 2. {next finding}
...

### Recommended Actions (Priority Order)

1. {highest impact fix — with exact file and content to add/change}
2. {next}
3. {next}
```

---

## Step 6: Offer to Apply Fixes

After presenting the report, ask:

> "Would you like me to apply any of these recommendations? I can update CLAUDE.md files, add memory entries, or install missing tools."

If the user agrees, apply the changes. For infrastructure changes (installing packages, modifying Dockerfiles), confirm before proceeding.

---

## Step 7: Resolve Fixed Errors

After applying fixes, mark the related errors as resolved so they don't appear in future analyses:

```sql
UPDATE agent_errors
SET resolved_at = NOW(), resolved_by = '{short description of fix}'
WHERE resolved_at IS NULL
  AND error_summary LIKE '%{pattern matching the fixed error}%';
```

Group the UPDATEs by finding — one UPDATE per fix applied. The `resolved_by` field should be a short human-readable note (e.g. "Installed jq", "Documented: environment_id = 3").

Report the counts:
```
Resolved: {n} errors marked as fixed
Remaining: {m} unresolved errors
```

---

## Important Rules

- **Read all errors before classifying.** Don't jump to conclusions from the first few.
- **Be specific.** "Documentation should be better" is useless. "Add X to Y file" is actionable.
- **Don't create busywork.** If an error happened once and is unlikely to recur, note it but don't recommend action.
- **Prioritise by impact.** Errors that block agent work entirely rank higher than minor inefficiencies.
- **Check current state.** Before recommending a fix, verify the issue hasn't already been resolved (e.g. the missing tool was installed since the error).
