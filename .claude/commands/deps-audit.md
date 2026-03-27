# Deps Audit — Scan all projects for npm vulnerabilities

You are scanning all projects for dependency vulnerabilities and storing results in `config_db.dep_audits`.

**Database connection:** `postgresql://urd:<password>@192.168.0.20:5439/config_db`
(Get password from: `grep URD_PASSWORD /home/coder/.claude/.env | cut -d= -f2`)

## What to scan

All backend directories under `/websites/*/backend/` that have a `package.json` and `node_modules/` directory.

## How to scan

For each project:

1. Run `npm audit --json` in the project's backend directory
2. Parse the JSON output to extract vulnerability counts from `metadata.vulnerabilities`
3. Store the results in `config_db.dep_audits`

```bash
CONFIG_DB="postgresql://urd:$(grep URD_PASSWORD /home/coder/.claude/.env | cut -d= -f2)@192.168.0.20:5439/config_db"

cd /websites/<project>/backend
AUDIT=$(npm audit --json 2>/dev/null)

# Extract counts
TOTAL=$(echo "$AUDIT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('metadata',{}).get('vulnerabilities',{}).get('total',0))")
CRITICAL=$(echo "$AUDIT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('metadata',{}).get('vulnerabilities',{}).get('critical',0))")
HIGH=$(echo "$AUDIT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('metadata',{}).get('vulnerabilities',{}).get('high',0))")
MODERATE=$(echo "$AUDIT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('metadata',{}).get('vulnerabilities',{}).get('moderate',0))")
LOW=$(echo "$AUDIT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('metadata',{}).get('vulnerabilities',{}).get('low',0))")
INFO=$(echo "$AUDIT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('metadata',{}).get('vulnerabilities',{}).get('info',0))")

psql "$CONFIG_DB" -c "
INSERT INTO dep_audits (project, total_vulnerabilities, critical, high, moderate, low, info, scanned_by)
VALUES ('<project>', $TOTAL, $CRITICAL, $HIGH, $MODERATE, $LOW, $INFO, 'claude')
"
```

## Output

Print a summary table after scanning all projects:

```
## Dependency Audit — 2026-03-13

| Project | Critical | High | Moderate | Low | Total |
|---------|----------|------|----------|-----|-------|
| kanban  | 0        | 3    | 1        | 1   | 5     |
| calify  | 1        | 0    | 2        | 0   | 3     |
...

Summary: X critical, Y high across Z projects
```

Flag any projects with critical or high vulnerabilities prominently. For those, also list the specific advisories:
```bash
cd /websites/<project>/backend && npm audit --json 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
for name, vuln in d.get('vulnerabilities', {}).items():
    sev = vuln.get('severity', '')
    if sev in ('critical', 'high'):
        via = ', '.join(v if isinstance(v, str) else v.get('title','') for v in vuln.get('via', []))
        print(f'  {sev.upper()}: {name} — {via}')
"
```

## Suggest actions

- For critical/high: suggest `npm audit fix` or specific package upgrades
- For moderate/low: note them but don't alarm
- If all clean: celebrate briefly

## History

To see trends, query previous scans:
```bash
psql "$CONFIG_DB" -c "SELECT project, scanned_at, critical, high, moderate, low, total_vulnerabilities FROM dep_audits ORDER BY scanned_at DESC LIMIT 50"
```
