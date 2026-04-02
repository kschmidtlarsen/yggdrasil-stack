# Yggdrasil - Infrastructure Stack & Multi-Stack Platform

## Overview

Yggdrasil is the infrastructure backbone of a multi-stack Docker platform running on the Unraid server (192.168.0.20). The platform uses a hub-and-spoke architecture: one infrastructure stack (Yggdrasil) provides shared services — PostgreSQL, monitoring, AI, and auto-deployment — while each application runs as an independent Portainer stack, git-managed from its own repository.

**Norse Mythology Naming:**
- **Yggdrasil** - The World Tree (infrastructure stack / docker-compose)
- **Bifrost** - Rainbow Bridge (Docker bridge network, shared across all stacks)
- **Urd** - Well of Fate (PostgreSQL 17 database)
- **Mimir** - The Wise One (AI orchestration / monitoring)

**Key design principles:**
- Infrastructure stack creates the Bifrost network; app stacks join it as `external: true`
- No cross-stack `depends_on` — apps use healthcheck + restart policies to handle Urd availability
- Infrastructure containers keep `yggdrasil-` prefix; app containers use clean names (e.g. `kanban`, `mimir`)
- Each app has `docker-compose.prod.yml` in its own repo root

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Multi-Stack Platform                           │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   Developer Machine (/websites/)                                  │
│         │                                                         │
│         ▼ git push (per repo)                                     │
│   ┌─────────────┐                                                │
│   │   GitHub    │ ← Source control + CI/CD                       │
│   └──────┬──────┘                                                │
│          │ GitHub Actions                                         │
│          ▼ Build Docker image → Push to ghcr.io                  │
│                                                                   │
│   ┌──────────────────────────────────────────────────────────┐   │
│   │              Portainer (Stack Orchestrator)               │   │
│   │                                                          │   │
│   │  ┌────────────────────────────────────────────────────┐  │   │
│   │  │  Yggdrasil Infra Stack (ID 53)                     │  │   │
│   │  │  Urd · Eir · Ollama · Chrome · Watchtower          │  │   │
│   │  │  Dashboard · Browser                                │  │   │
│   │  │  ← Creates Bifrost network                         │  │   │
│   │  └──────────────────────┬─────────────────────────────┘  │   │
│   │                         │ Bifrost (external: true)        │   │
│   │  ┌──────────────────────┴─────────────────────────────┐  │   │
│   │  │  App Stacks (IDs 54–66)                            │  │   │
│   │  │  kanban · mimir · playwright · cos · calify        │  │   │
│   │  │  grablist · nighttales · schmidt-larsen            │  │   │
│   │  │  sorring3d · sorring-udlejning · wodforge          │  │   │
│   │  │  nytsyn · stuffbase                                │  │   │
│   │  │  ← Each git-managed from own repo                  │  │   │
│   │  └────────────────────────────────────────────────────┘  │   │
│   │                                                          │   │
│   └──────────────────────────────────────────────────────────┘   │
│                         │                                         │
│                         ▼                                         │
│                ┌──────────────┐                                   │
│                │  Cloudflare  │ ← Tunnel + Access protection     │
│                │  Tunnel      │                                   │
│                └──────┬───────┘                                   │
│                       │                                           │
│                       ▼                                           │
│                  Internet                                         │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

**Infrastructure Map:** `/home/coder/.claude/infrastructure.yml` (single source of truth)

## Portainer Stacks

All stacks are git-managed. The infra stack deploys from this repo (`yggdrasil-stack`); each app stack deploys from its own repo's `docker-compose.prod.yml`.

| Stack ID | Name | Type | Repo | Services |
|----------|------|------|------|----------|
| 53 | yggdrasil | infra | yggdrasil-stack | Urd, Dashboard, Eir, Ollama, Chrome, Browser, Watchtower |
| 54 | kanban | app | kanban | kanban |
| 55 | mimir | app | mimir | mimir |
| 56 | playwright | app | playwright | playwright |
| 57 | cos | app | cos | cos |
| 58 | calify | app | calify | calify |
| 59 | grablist | app | grablist | grablist |
| 60 | nighttales | app | nighttales | nighttales |
| 61 | schmidt-larsen | app | schmidt-larsen | schmidt-larsen |
| 62 | sorring3d | app | sorring3d | sorring3d |
| 63 | sorring-udlejning | app | sorring-udlejning | sorring-udlejning |
| 64 | wodforge | app | wodforge | wodforge |
| 65 | nytsyn | app | nytsyn | nytsyn |
| 66 | stuffbase | app | stuffbase | stuffbase |

> **IMPORTANT:** When using Portainer MCP tools, always use `environment_id: 3`.
> IDs 1 and 2 do not exist. The `docker` CLI is not available — use Portainer MCP tools instead.

## Port Scheme

**Port Allocation:**
- **61xx** - Internal tools (.exe.pm domains, Cloudflare Access protected)
- **62xx** - External websites (public domains)
- **5439** - PostgreSQL (Urd) external access
- **9000** - Portainer web UI

**Internal tools (61xx):**
| Service | Container | Stack ID | Port | Domain |
|---------|-----------|----------|------|--------|
| Kanban | kanban | 54 | 6101 | kanban.exe.pm |
| Playwright | playwright | 56 | 6102 | playwright.exe.pm |
| Mimir | mimir | 55 | 6103 | mimir.exe.pm |
| CoS | cos | 57 | 6106 | cos.exe.pm |
| Chrome | yggdrasil-chrome | 53 | 6107 | — (CDP only) |

**External sites (62xx):**
| Service | Container | Stack ID | Port | Domain |
|---------|-----------|----------|------|--------|
| Calify | calify | 58 | 6201 | calify.it |
| WODForge | wodforge | 64 | 6202 | wodforge.exe.pm |
| Sorring 3D | sorring3d | 62 | 6203 | sorring3d.dk |
| Sorring Udlejning | sorring-udlejning | 63 | 6204 | sorringudlejning.dk |
| Grablist | grablist | 59 | 6205 | grablist.org |
| Night Tales | nighttales | 60 | 6206 | nighttales.cloud |
| Schmidt Larsen | schmidt-larsen | 61 | 6207 | schmidtlarsen.dk |

**Infrastructure (Stack 53):**
| Service | Container | Port | Notes |
|---------|-----------|------|-------|
| Urd (PostgreSQL) | yggdrasil-urd | 5439 | Database |
| Yggdrasil Dashboard | yggdrasil-dashboard | — | Stack dashboard |
| Eir | yggdrasil-eir | — | Backup service |
| Ollama | yggdrasil-ollama | — | AI models |
| Chrome | yggdrasil-chrome | 6107 | CDP browser |
| Browser | yggdrasil-browser | — | Browser service |
| Watchtower | yggdrasil-watchtower | — | Auto-update |
| Portainer | — | 9000 | Container management UI (standalone) |

## Database Access (Urd)

**External Access:** 192.168.0.20:5439
**Internal Access:** urd:5432 (via Bifrost network)
**Credentials:** Stored in `/home/coder/.claude/.env`
**Database Naming:** `{projectname}_db`

**Connection String Format (Internal — from containers):**
```
postgresql://urd:{password}@urd:5432/{database}?sslmode=disable
```

**Connection String Format (External — from dev machine):**
```
postgresql://urd:{password}@192.168.0.20:5439/{database}?sslmode=disable
```

**Databases:**
| Project | Database | Schema |
|---------|----------|--------|
| kanban | kanban_db | public |
| playwright | playwright_db | public |
| cos | cos_db | public |
| mimir | mimir_db | public |
| calify | calify_db | public |
| wodforge | wodforge_db | public |
| sorring3d | sorring3d_db | public |
| sorring-udlejning | sorring_db | public |
| grablist | grablist_db | public |
| nighttales | nighttales_db | public |

## Service Reference

### Portainer

**Web UI:** http://192.168.0.20:9000
**Purpose:** Stack orchestration, container management, image rollback
**Infra Stack ID:** 53 | **Environment ID:** 3

> **IMPORTANT:** When using Portainer MCP tools, always use `environment_id: 3`.
> IDs 1 and 2 do not exist. The `docker` CLI is not available — use Portainer MCP tools instead.

**Common Operations:**
- View container logs
- Restart containers
- Update environment variables
- Roll back to previous image
- Monitor resource usage

### Watchtower

**Purpose:** Automated container updates
**Interval:** 5 minutes
**Trigger:** Detects new images in registry, pulls and restarts containers

**Deployment Flow:**
1. Developer pushes to GitHub `main` branch
2. GitHub Actions builds Docker image and pushes to registry
3. Watchtower detects new image within 5 minutes
4. Watchtower pulls image and restarts container
5. Health endpoint shows new BUILD_COMMIT

### Cloudflare

**Dashboard:** https://dash.cloudflare.com
**Domains:** exe.pm, calify.it, grablist.org, wodforge.dk, sorringudlejning.dk

**Cloudflare Tunnel:** Routes traffic from internet to Yggdrasil (192.168.0.20)

**DNS Setup:**
```
Type: CNAME
Name: {subdomain}
Target: {tunnel-id}.cfargotunnel.com
Proxy: Enabled (orange cloud)
```

**Cloudflare Access:** Protected sites (.exe.pm) require service token headers:
```bash
CF-Access-Client-Id: ${CF_ACCESS_CLIENT_ID}
CF-Access-Client-Secret: ${CF_ACCESS_CLIENT_SECRET}
```

Internal tools (61xx ports) protected:
- kanban.exe.pm, playwright.exe.pm, mimir.exe.pm, cos.exe.pm

Public sites (62xx ports, no Access):
- calify.it, wodforge.exe.pm, sorring3d.dk, sorringudlejning.dk, grablist.org, nighttales.cloud

## Secret Management

**Centralized Store:** `/home/coder/.claude/.env`

**Format:**
- Shared secrets (no prefix): `GITHUB_TOKEN`, `SONAR_TOKEN`, `CF_ACCESS_CLIENT_ID`
- Project-specific secrets: `{PROJECTNAME}_SECRET_NAME`
- Each Portainer stack references these values via its environment variables

**Example:**
```bash
# Shared
GITHUB_TOKEN=ghp_...
SONAR_TOKEN=...

# Yggdrasil Infrastructure
PORTAINER_URL=http://192.168.0.20:9000
PORTAINER_API_KEY=ptr_...
URD_HOST=192.168.0.20
URD_PORT=5439
URD_USER=urd
URD_PASSWORD=...

# Project-specific
CALIFY_DATABASE_URL=postgresql://urd:...@urd:5432/calify_db?sslmode=disable
CALIFY_JWT_SECRET=...
CALIFY_RESEND_API_KEY=...
```

## CI/CD Pipeline

```
Code Push → GitHub Actions → Build Docker Image → Push to ghcr.io → Watchtower → Auto-deploy
```

**GitHub Actions Workflow:** Each app has `.github/workflows/docker.yml` that:
1. Runs tests
2. Builds from `Dockerfile.yggdrasil`
3. Tags with commit SHA and `:latest`
4. Pushes to `ghcr.io/kschmidtlarsen/<app>`
5. Triggers on push to main

**Organization:** kschmidtlarsen

**Check build status:**
```bash
gh run list --repo kschmidtlarsen/<app> --limit 1
```

## Build Tracking

All services expose build metadata via `/api/health`:

```json
{
  "status": "ok",
  "timestamp": "2026-03-12T10:30:00Z",
  "database": "connected",
  "build": {
    "commit": "a1b2c3d4e5f6...",
    "timestamp": "2026-03-12T10:25:00Z",
    "version": "1.2.3"
  }
}
```

**Purpose:**
- Verify deployment succeeded
- Cache-busting for frontend assets
- Deployment tracking in Kanban cards

**Check individual services:**
```bash
curl http://192.168.0.20:6101/api/health  # kanban
curl http://192.168.0.20:6205/api/health  # grablist
curl https://kanban.exe.pm/api/health     # via Cloudflare
```

## Adding a New App

1. Create the app repo with `Dockerfile.yggdrasil` and `docker-compose.prod.yml`
2. In `docker-compose.prod.yml`, join the Bifrost network as external:
   ```yaml
   networks:
     bifrost:
       external: true
   ```
3. Use a clean container name (no `yggdrasil-` prefix) and assign the next available port (61xx/62xx)
4. Do NOT add `depends_on: urd` — instead use healthcheck + `restart: unless-stopped` to handle Urd availability
5. Add GitHub Actions workflow (`.github/workflows/docker.yml`) for ghcr.io builds
6. Create database in Urd (see Common Tasks below)
7. Add connection string and secrets to `/home/coder/.claude/.env`
8. Create a new Portainer stack (git-managed from the app repo) with the next stack ID
9. Configure Cloudflare Tunnel for the domain

## Common Tasks

### Deploy a Project
```bash
cd /websites/{project}
git add .
git commit -m "Description"
git push origin main

# GitHub Actions builds Docker image
# Watchtower auto-deploys within 5 minutes
```

### Check Deployment Status
```bash
# Via GitHub Actions
gh run list --repo kschmidtlarsen/{project} --limit 1

# Via health endpoint
curl -sL https://{domain}/api/health | jq '.build'
```

### Create New Database
```bash
# Connect to Urd
psql -h 192.168.0.20 -p 5439 -U urd -W

# Create database
CREATE DATABASE {projectname}_db;

# Grant permissions
GRANT ALL PRIVILEGES ON DATABASE {projectname}_db TO urd;

# Add connection string to /home/coder/.claude/.env
{PROJECTNAME}_DATABASE_URL=postgresql://urd:{password}@urd:5432/{projectname}_db?sslmode=disable
```

### Manual Container Restart
```bash
# Via Portainer MCP tools (preferred)
# Use container_action with the container name

# Via Portainer Web UI
# 1. Open http://192.168.0.20:9000
# 2. Navigate to Containers
# 3. Select container → Restart
```

### Rollback Deployment
```bash
# Option 1: Git revert (preferred)
git revert HEAD
git push origin main
# Watchtower auto-deploys reverted code within 5 minutes

# Option 2: Portainer manual rollback
# 1. Open http://192.168.0.20:9000
# 2. Navigate to Containers → {service}
# 3. Click "Recreate" and select previous image tag
```

### View Container Logs
```bash
# Via Portainer MCP tools (preferred)
# Use container_logs with the container ID

# Via Portainer Web UI
# 1. Open http://192.168.0.20:9000
# 2. Navigate to Containers → {service}
# 3. Click "Logs"
```

## Uptime Kuma Monitoring

**Dashboard:** http://192.168.0.20:3001
**Status page:** http://192.168.0.20:3001/status/yggdrasil
**Sync tool:** `node /websites/yggdrasil/scripts/kuma-sync.js`

All Yggdrasil monitors are managed via the kuma-sync tool and tagged `yggdrasil` in Uptime Kuma.

```bash
# Sync monitors to match config (idempotent)
node scripts/kuma-sync.js sync

# Show managed monitor status
node scripts/kuma-sync.js status

# Pause monitors before maintenance
node scripts/kuma-sync.js pause kanban
node scripts/kuma-sync.js pause all

# Resume after maintenance
node scripts/kuma-sync.js resume kanban

# Delete all managed monitors and recreate
node scripts/kuma-sync.js nuke && sleep 15 && node scripts/kuma-sync.js sync
```

**Adding monitors for a new service:** Edit `scripts/kuma-monitors.js`, add a service entry, run `sync`.

**Monitor types per service:**
- Internal Health: keyword check on `http://192.168.0.20:<port>/api/health`
- DB Connected: keyword check for database status (services that expose it)
- External: HTTP check on the public domain

## Disaster Recovery

Full rebuild guide: `/websites/eir/REBUILD.md`
Also copied to backup root: `/mnt/user/backup/websites/REBUILD.md`

Eir backs up all 13 databases, 2 upload volumes, .env, docker-compose.yml, and REBUILD.md twice daily.

## Volumes

**Named volumes (Docker-managed):**
- `yggdrasil-urd-data` - PostgreSQL data
- `yggdrasil-ollama-models` - Ollama AI models

**File uploads (bind-mounted from Unraid share):**
- `/mnt/user/websites/files/sorring3d` → `/app/uploads` (sorring3d) + `/volumes/sorring3d` (eir, read-only)
- `/mnt/user/websites/files/sorring-udlejning` → `/app/uploads` (sorring-udlejning) + `/volumes/sorring-udlejning` (eir, read-only)
- `/mnt/user/websites/files/{project}` — convention for all future project file storage

## Troubleshooting

**Container not starting:**
```bash
# Check container health endpoint
curl http://192.168.0.20:<port>/api/health

# Check logs via Portainer MCP tools
# Use container_logs with the container ID
```

**Frontend shows "Not Found":**
- Ensure container has latest image (force pull in Portainer)
- Check `frontendPath` in server.js uses production path

**502 Bad Gateway via Cloudflare:**
- Container is down or not responding
- Check Cloudflare Tunnel points to `http://192.168.0.20:<port>`

**Database connection issues:**
- Verify database exists in Urd
- Check DATABASE_URL in the app stack's environment variables in Portainer
- Test external connectivity: `psql -h 192.168.0.20 -p 5439 -U urd -W`
- App containers handle Urd restarts via healthcheck + restart policy (no `depends_on` across stacks)

## CLI Tools

Available on the development machine:
- `gh` - GitHub CLI (repos, actions, PRs)
- `psql` - PostgreSQL client
- `curl` - HTTP requests
- `jq` - JSON processing
