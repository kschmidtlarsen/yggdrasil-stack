# Yggdrasil Stack

Infrastructure stack for a self-hosted, multi-stack Docker platform — the shared PostgreSQL database, AI inference, backup guardian, auto-deployer, and ops dashboard that every application stack depends on.

## Overview

Yggdrasil ("the World Tree" in Norse mythology) is the infrastructure backbone of a hub-and-spoke Docker platform running on an Unraid server (`192.168.0.20`). This repository holds the `docker-compose.yml` and database bootstrap scripts for the **infrastructure stack** only.

The platform is split into:

- **One infrastructure stack** (this repo) — provides shared services: the database, local AI, backups, browser-based OAuth, auto-deployment, and the ops dashboard. It also creates the shared `bifrost` Docker network.
- **Many application stacks** — each app (Kanban, Mimir, Calify, Grablist, etc.) lives in its own repository with its own `docker-compose.prod.yml`, and joins the platform by attaching to the `bifrost` network as `external: true`.

Design principles:

- The infra stack creates the `bifrost` bridge network; app stacks join it as external.
- No cross-stack `depends_on` — apps handle database availability via healthchecks and `restart: unless-stopped`.
- Infrastructure containers keep the `yggdrasil-` prefix (e.g. `yggdrasil-urd`); app containers use clean names.
- Secrets live in a single central `.env` file on the host, mounted read-only into containers — never in this compose file or in Portainer stack env vars (except the two infra services that need compose-time interpolation).

## Tech stack

- **Docker Compose** (v3-style, single stack file) orchestrated via **Portainer** on Unraid
- **PostgreSQL 17** with the `pgvector` extension (`pgvector/pgvector:pg17` image)
- **Ollama** for local AI inference (GPU passthrough via the Unraid NVIDIA plugin)
- **Watchtower** (`nickfedor/watchtower` fork) for automatic image updates from GHCR
- **Firefox + noVNC** (`jlesage/firefox`) for browser-based OAuth flows
- Node.js images for the Yggdrasil dashboard, Eir, and the design system (built in their own repos, pulled from `ghcr.io/kschmidtlarsen/*`)

## Architecture

### Services in this stack

| Service | Container | Image | Host port → container | Purpose |
|---------|-----------|-------|-----------------------|---------|
| **Urd** | `yggdrasil-urd` | `pgvector/pgvector:pg17` | `5439 → 5432` | PostgreSQL 17 database ("Well of Fate") shared by all apps |
| **Yggdrasil Dashboard** | `yggdrasil-dashboard` | `ghcr.io/kschmidtlarsen/yggdrasil:latest` | `6100 → 3000` | Infrastructure operations platform |
| **Eir** | `yggdrasil-eir` | `ghcr.io/kschmidtlarsen/eir:latest` | `6108 → 3000` | Backup & recovery guardian ("Goddess of Healing") |
| **Ollama** | `yggdrasil-ollama` | `ollama/ollama:latest` | `6109 → 11434` | Local AI inference / embeddings (GPU-accelerated) |
| **Browser** | `yggdrasil-browser` | `jlesage/firefox:latest` | `6111 → 5800` | Firefox + noVNC to complete OAuth flows for remote MCP servers |
| **Design system** | `yggdrasil-design` | `ghcr.io/kschmidtlarsen/design-system:latest` | `6110 → 80` | "Graphite Iris" shared CSS/tokens served publicly to all apps |
| **Watchtower** | `yggdrasil-watchtower` | `nickfedor/watchtower:latest` | — | Polls GHCR every 60s and auto-updates labeled containers |

All services attach to the `bifrost` network. Only containers labeled `com.centurylinklabs.watchtower.enable=true` are auto-updated (Urd, dashboard, Eir, design system are enabled; Ollama, browser, and Watchtower itself are not).

### Data flow

```
Developer (git push) ──▶ GitHub ──Actions──▶ ghcr.io/kschmidtlarsen/<app>
                                                    │
                        Watchtower (polls 60s) ◀────┘
                                │ pulls new image, restarts container
                                ▼
  ┌──────────────── INFRA STACK (this repo) ───── creates bifrost network ──┐
  │  Urd (PostgreSQL) ◀── all apps connect here                             │
  │  Eir ── backs up all DBs + upload volumes twice daily                   │
  │  Ollama ── local inference for Mimir                                    │
  │  Dashboard (:6100)   Browser (:6111)   Design (:6110)                   │
  └──────────────────────────────┬──────────────────────────────────────────┘
                                 │ bifrost (external: true)
       APP STACKS (kanban, mimir, calify, forseti, …) each in its own repo
```

### Database bootstrap

On first startup, Urd runs the SQL in `init/` (mounted at `/docker-entrypoint-initdb.d`):

- `01-create-databases.sql` — creates one database per project (`{project}_db`), all owned by `urd` with UTF-8 encoding. Includes `kanban_db`, `mimir_db`, `calify_db`, `grablist_db`, `cos_db`, `forseti_db`, `stuffbase_db`, `spiir_db`, `nighttales_db`, `sorring3d_db`, `sorring_udlejning_db`, `wodforge_db`, `schmidtlarsen_db`, `eir_db`, `config_db`, `yggdrasil_db`, `strider_db`, `huginn_db`, `opportunity_scout_db`, `bragi_db`, `muninn_db`, `warehouse_db`, `legevenner_db`.
- `02-create-extensions.sql` — enables `uuid-ossp` and `pgcrypto` on each database (plus `pg_trgm` on `mimir_db` for fuzzy search).

> These scripts run only on an empty data volume. Databases added after initial bootstrap must be created manually against a running Urd.

## Getting started

This repo is deployed as a Portainer stack, not run standalone with the Docker CLI. To bring it up on a fresh host:

### Prerequisites

- Unraid (or any Docker host) with Portainer and the NVIDIA container runtime (for Ollama GPU passthrough)
- The following host paths must exist and hold their expected contents:
  - `/mnt/user/appdata/claude/.env` — central secrets file (see [Configuration](#configuration))
  - `/mnt/user/appdata/claude/postgres-password` — single-line file with the Postgres password
  - `/mnt/user/websites/yggdrasil-stack/watchtower-config.json` — GHCR registry auth for Watchtower (gitignored)
  - `/mnt/user/backup/websites` — Eir backup target
  - `/mnt/user/websites/files/{sorring3d,sorring-udlejning,stuffbase}` — app upload volumes (read-only into Eir)

### Deploy

1. Clone this repo onto the host (e.g. `/mnt/user/websites/yggdrasil-stack`).
2. In Portainer, create a git-managed stack pointing at this repo's `docker-compose.yml` (infra stack ID `53`, environment ID `3`).
3. Ensure the `POSTGRES_USER` / `POSTGRES_PASSWORD` stack env vars are set (see below).
4. Deploy. Urd bootstraps the databases on first run; the other services join `bifrost` and come up behind their healthchecks.

App stacks are deployed separately, each from its own repository.

## Configuration

Secrets are centralized in `/mnt/user/appdata/claude/.env`, mounted read-only as `/app/.env` into app containers (loaded via `dotenv`). This compose file itself references almost no secrets. The infra exceptions:

| Variable | Purpose | Required? |
|----------|---------|-----------|
| `POSTGRES_USER` | Postgres superuser name (`urd`) | Yes (Portainer stack env, for the Urd service) |
| `POSTGRES_PASSWORD` | Postgres password — supplied to Urd via the `postgres-password` file mount, not this var directly | Yes (as the password file) |

`.env.example` documents the shape of the central secrets file consumed by app stacks (names only — never commit values):

| Variable | Purpose |
|----------|---------|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | Urd credentials |
| `CLAUDE_CODE_OAUTH_TOKEN` | Mimir — Claude Code auth |
| `MIMIR_ENCRYPTION_SECRET` | Mimir — at-rest encryption |
| `MIMIR_INTERNAL_API_TOKEN` | Mimir — internal API auth |
| `GITHUB_TOKEN` | Shared — GitHub API / GHCR access |
| `JWT_SECRET` | Shared — JWT signing |
| `WEBSOCKET_KEY` | Shared — WebSocket auth |
| `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` | Payments (Calify, Sorring3D, Night Tales) |
| `OPENAI_API_KEY` | OpenAI (Night Tales, Sorring Udlejning, WODForge) |
| `RESEND_API_KEY` | Transactional email |

Notable service-level environment set in `docker-compose.yml`:

- **Urd** — tuned Postgres flags (`max_connections=200`, `shared_buffers=256MB`, `pg_stat_statements` preloaded); password via `POSTGRES_PASSWORD_FILE`.
- **Eir** — `URD_HOST=urd`, `BACKUP_SCHEDULE="0 3,15 * * *"` (twice daily), `BACKUP_CAP_GB=100`.
- **Ollama** — `OLLAMA_KEEP_ALIVE=-1` (models stay in VRAM), `OLLAMA_NUM_CTX=32768`, NVIDIA GPU passthrough.
- **Watchtower** — label-gated updates, `WATCHTOWER_POLL_INTERVAL=60`, `WATCHTOWER_CLEANUP=true`.

## Project structure

```
yggdrasil-stack/
├── docker-compose.yml            # The infra stack definition (all services above)
├── init/
│   ├── 01-create-databases.sql   # Creates one DB per project on first Urd boot
│   └── 02-create-extensions.sql  # Enables uuid-ossp, pgcrypto (+ pg_trgm on mimir)
├── Dockerfile.template           # Reference Express-app Dockerfile for new apps
├── .github/templates/
│   └── docker-build-template.yml # Reference GitHub Actions workflow for app repos
├── .env.example                  # Documents the central secrets file (names only)
├── watchtower-config.json        # GHCR registry auth for Watchtower (gitignored)
├── package.json                  # dotenv + socket.io-client (utility deps)
├── .gitmodules                   # App repos referenced as submodules under apps/
├── CLAUDE.md                     # Full platform operations runbook
└── scripts/                      # (empty)
```

`Dockerfile.template` and `.github/templates/docker-build-template.yml` are **templates for new app repos**, not used to build anything in this repo. Copy them into an app as `Dockerfile.yggdrasil` and `.github/workflows/docker.yml` respectively. `.gitmodules` links several app repositories as submodules under `apps/` for convenience.

## Deployment

The infra stack is git-managed in Portainer and redeployed by pulling this repo. Application images follow the platform's standard pipeline:

```
git push (main) → GitHub Actions → build image → push to ghcr.io/kschmidtlarsen/<app> → Watchtower auto-deploy
```

- **Watchtower** polls GHCR every 60 seconds and updates any container labeled `com.centurylinklabs.watchtower.enable=true`, then removes the old image.
- **Portainer:** infra stack ID `53`, environment ID `3`. Never pass `stackFileContent` when updating via API — it converts the stack from git-managed to web-editor mode. Commit changes to `docker-compose.yml`, push, then redeploy.

### CI/CD for apps

Each application repo carries a workflow based on `.github/templates/docker-build-template.yml`, which:

1. Logs in to `ghcr.io` using the GitHub Actions token.
2. Builds from the app's `Dockerfile.yggdrasil`.
3. Tags the image `:latest` and with the commit SHA.
4. Pushes to `ghcr.io/${{ github.repository }}` on push to `main` (or manual dispatch).

## Related services & links

- **Design system (Graphite Iris):** served from this stack at port `6110` / `design.exe.pm` (public). All `*.exe.pm` apps link `iris.css` from it — see https://design.exe.pm.
- **Portainer:** container/stack management at `http://192.168.0.20:9000`.
- **Application stacks:** Kanban, Mimir, Calify, Grablist, CoS, Forseti, Stuffbase, Spiir, WODForge, Night Tales, Sorring 3D, Sorring Udlejning, Schmidt Larsen — each in its own `kschmidtlarsen/*` repository.
- **Operations runbook:** see `CLAUDE.md` for the full port map, database access, secret management, disaster recovery, and common tasks.
