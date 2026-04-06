---
name: ops-health
description: Check infrastructure health - Yggdrasil containers, Urd database, service endpoints
user-invocable: true
---

# /ops-health - Infrastructure Health Check

Automated health monitoring for all services on Yggdrasil (Docker on Unraid) with Urd PostgreSQL. When issues are found, diagnose with debug skill and create Kanban cards for resolution.

## Infrastructure Overview

- **Yggdrasil**: Docker host at 192.168.0.20 (Unraid)
- **Portainer**: Container management on port 9000
- **Urd**: PostgreSQL 17 database server
- **Bifrost**: Docker network connecting services
- **Deployment**: GitHub → Actions → Docker image → Portainer → Container restart

---

## Phase 1: Quick Health Check

Check all services (external domains + internal endpoints + infrastructure):

```bash
echo "=== Infrastructure Health Check ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Infrastructure services
echo "=== Infrastructure Services ==="

# Urd (PostgreSQL)
if docker exec yggdrasil-urd pg_isready -U urd -d postgres >/dev/null 2>&1; then
  echo "✅ Urd (PostgreSQL): OK"
else
  echo "❌ Urd (PostgreSQL): FAIL"
fi

# Mimir (AI Orchestration)
status=$(curl -s -o /dev/null -w "%{http_code}" "http://192.168.0.20:6103/api/health" 2>/dev/null || echo "000")
if [ "$status" = "200" ]; then
  echo "✅ Mimir:6103: OK"
else
  echo "❌ Mimir:6103: FAIL (HTTP $status)"
fi

# PgAdmin
status=$(curl -s -o /dev/null -w "%{http_code}" "http://192.168.0.20:6104/" 2>/dev/null || echo "000")
if [ "$status" = "200" ]; then
  echo "✅ PgAdmin:6104: OK"
else
  echo "❌ PgAdmin:6104: FAIL (HTTP $status)"
fi

echo ""
echo "=== Application Services (via External Domains) ==="
for site in kanban.exe.pm playwright.exe.pm chiefofstaff.exe.pm calify.it wodforge.exe.pm sorring3d.dk sorringudlejning.dk grablist.org nighttales.exe.pm; do
  endpoint="/api/health"

  status=$(curl -s -o /dev/null -w "%{http_code}" "https://$site$endpoint" 2>/dev/null || echo "000")
  time=$(curl -s -o /dev/null -w "%{time_total}" "https://$site$endpoint" 2>/dev/null || echo "N/A")
  if [ "$status" = "200" ]; then
    echo "✅ $site: OK (${time}s)"
  else
    echo "❌ $site: FAIL (HTTP $status)"
  fi
done

echo ""
echo "=== Internal Service Checks ==="
# Check internal ports directly (redundant with external, but useful for debugging routing issues)
declare -A services=(
  ["6101"]="kanban"
  ["6102"]="playwright"
  ["6106"]="cos"
  ["6201"]="calify"
  ["6202"]="wodforge"
  ["6203"]="sorring3d"
  ["6204"]="sorring-udlejning"
  ["6205"]="grablist"
  ["6206"]="nighttales"
)

for port in "${!services[@]}"; do
  name="${services[$port]}"
  status=$(curl -s -o /dev/null -w "%{http_code}" "http://192.168.0.20:$port/api/health" 2>/dev/null || echo "000")
  if [ "$status" = "200" ]; then
    echo "✅ $name:$port: OK"
  else
    echo "❌ $name:$port: FAIL (HTTP $status)"
  fi
done
```

**If all services return 200 OK:** Report success and exit.

**If any failures detected:** Proceed to Phase 2.

---

## Phase 2: Detailed Investigation

For each failed service, gather detailed information:

### Container Status via Portainer MCP

Use Portainer MCP to check container health:

```
Tool: mcp__portainer__list_containers
Returns: Array of containers with status, state, health

Tool: mcp__portainer__inspect_container
Arguments: { containerId: "yggdrasil-{project}" }
Returns: Detailed container info, env vars, restart count
```

**Check for:**
- Container state: running, exited, restarting
- Restart count: High restart count = crash loop
- Health check status: healthy, unhealthy, none
- Resource usage: Memory/CPU limits

### Container Logs via Docker

```bash
# Recent errors
docker logs yggdrasil-{project} --tail 100 --since "10m" | grep -i error

# Check for crashes
docker logs yggdrasil-{project} --tail 500 | grep -E "(Error|Exception|FATAL|crashed)"

# Database connection errors
docker logs yggdrasil-{project} --tail 200 | grep -i "ECONNREFUSED\|database"
```

### GitHub Actions Status

```bash
# Check recent deployments
gh api repos/kschmidtlarsen/{repo}/actions/runs?per_page=5 | \
  jq '.workflow_runs[] | {
    status: .status,
    conclusion: .conclusion,
    created_at: .created_at,
    run_id: .id
  }'

# If last build failed, get logs
gh run view {run-id} --repo kschmidtlarsen/{repo} --log
```

### Database Connectivity

```bash
# Check Urd database from Yggdrasil host
docker exec yggdrasil-{project} psql $DATABASE_URL -c "SELECT 1;" 2>&1

# Or via health endpoint database check
curl -s "https://{domain}/api/health" | jq '.checks.database'
```

---

## Phase 3: Diagnosis

**For each failed service, invoke debug skill:**

```
Use Skill tool: skill: "debug", args: "{projectId} \"Service {domain} health check failing\""
```

Debug skill will:
1. Collect symptoms (what's actually broken)
2. Gather evidence (logs, recent changes, metrics)
3. Analyze root cause (why it's broken)
4. Provide diagnosis and recommended fix

**Wait for debug skill response:**
```
DIAGNOSIS: {root cause description}
RECOMMENDED FIX: {specific actions needed}
```

---

## Phase 4: Issue Tracking

**For each diagnosed issue, create a Kanban bug card:**

Use Kanban MCP tool `create_card`:
```
Arguments: {
  title: "Service {project} down: {brief root cause}",
  description: "## Symptoms\n{what's broken}\n\n## Root Cause\n{diagnosis from debug skill}\n\n## Evidence\n{key logs/metrics}\n\n## Recommended Fix\n{steps to resolve}",
  projectId: "{project}",
  type: "bug",
  priority: "high",
  labels: ["infrastructure", "ops-health"],
  acceptanceCriteria: [
    "Service returns 200 on /api/health",
    "Container running without restarts",
    "No errors in container logs"
  ]
}
```

**Move card to "Discovered" column** so another agent can pick it up via `/bug-hotfix`.

---

## Health Report Format

After all checks complete, output summary:

```markdown
## Infrastructure Health Report

**Timestamp:** {ISO date}
**Infrastructure:** Yggdrasil (192.168.0.20) + Urd PostgreSQL 17

### Infrastructure Services
| Service | Port | Status | Container State | Issues |
|---------|------|--------|-----------------|--------|
| Urd (PostgreSQL) | 5439 | ✅ OK | Running | None |
| Mimir (AI Orchestration) | 6103 | ✅ OK | Running | None |
| PgAdmin | 6104 | ✅ OK | Running | None |

### Application Services - Internal Tools (61xx)
| Service | Domain | Port | Status | Response | Container | Issues |
|---------|--------|------|--------|----------|-----------|--------|
| Kanban | kanban.exe.pm | 6101 | ✅ OK | 0.24s | Running | None |
| Playwright | playwright.exe.pm | 6102 | ✅ OK | 0.18s | Running | None |
| CoS | chiefofstaff.exe.pm | 6106 | ✅ OK | 0.22s | Running | None |

### Application Services - External Websites (62xx)
| Service | Domain | Port | Status | Response | Container | Issues |
|---------|--------|------|--------|----------|-----------|--------|
| Calify | calify.it | 6201 | ✅ OK | 0.31s | Running | None |
| WODForge | wodforge.exe.pm | 6202 | ❌ FAIL | Timeout | Restarting | Card #123 |
| Sorring 3D | sorring3d.dk | 6203 | ✅ OK | 0.28s | Running | None |
| Sorring Udlejning | sorringudlejning.dk | 6204 | ✅ OK | 0.35s | Running | None |
| Grablist | grablist.org | 6205 | ✅ OK | 0.19s | Running | None |
| Night Tales | nighttales.exe.pm | 6206 | ✅ OK | 0.27s | Running | None |

### Issues Created
- [Card #123](http://192.168.0.20:6101/board?card=123) - WODForge database connection failing (retrying)

### Infrastructure Status
- **Portainer:** http://192.168.0.20:9000 (accessible)
- **Urd Database:** Connected, {N} active connections
- **Watchtower:** Running (auto-updates enabled)
- **GitHub Actions:** {N} successful, {M} failed in last 24h

### Summary
- **Total Services:** 14 (4 infrastructure + 10 applications)
- **Healthy:** 13
- **Degraded:** 1
- **Cards Created:** 1
```

---

## Troubleshooting Reference

### Common Issues

**Container in restart loop:**
- Check logs: `docker logs yggdrasil-{project} --tail 500`
- Check env vars in Portainer stack
- Verify DATABASE_URL is correct
- Check port conflicts: `docker ps | grep {port}`

**Service returns 502/503:**
- Container may be starting up (check uptime)
- Health check endpoint may be failing
- Database connection issues (check Urd)

**GitHub Actions build failed:**
- View logs: `gh run view {run-id} --log`
- Common causes: Syntax error, missing deps, test failure
- Rerun: `gh run rerun {run-id}`

**Database connection refused:**
- Check Urd is running: `docker ps | grep urd`
- Verify DATABASE_URL in Portainer env vars
- Check network: Container must be on Bifrost network

---

## Infrastructure Mapping

**All infrastructure details are maintained in:** `/home/coder/.claude/infrastructure.yml`

This YAML file is the single source of truth for:
- Service names, containers, ports
- Health check endpoints
- GitHub repositories
- Database names
- Purpose and descriptions

**Query examples:**
```bash
# List all services by type
cat /home/coder/.claude/infrastructure.yml | yq '.services[] | select(.type == "external") | .name'

# Get service details
cat /home/coder/.claude/infrastructure.yml | yq '.services[] | select(.name == "kanban")'

# List all health check endpoints
cat /home/coder/.claude/infrastructure.yml | yq '.services[] | .health_check.endpoint'
```

**Quick reference:**
- **Infrastructure services**: Urd (PostgreSQL:5439), PgAdmin (:6104), Mimir (:6103), Watchtower
- **Internal tools (61xx)**: Kanban, Playwright, CoS
- **External websites (62xx)**: Calify, WODForge, Sorring 3D, Sorring Udlejning, Grablist, Night Tales
- **Total services**: 14 (4 infrastructure + 10 applications)

---

## Monitoring Links

- **Portainer:** http://192.168.0.20:9000
- **Kanban Board:** http://192.168.0.20:6101 (internal) or https://kanban.exe.pm
- **GitHub Actions:** https://github.com/kschmidtlarsen?tab=repositories
- **SonarCloud:** https://sonarcloud.io/organizations/kschmidtlarsen/projects
