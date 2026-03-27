# Doc Audit — Compare non-code files against approved baselines

You are auditing all non-code files across the platform against their approved baselines stored in `config_db.doc_baselines`.

**Database connection:** `postgresql://urd:<password>@192.168.0.20:5439/config_db`
(Get password from: `grep URD_PASSWORD /home/coder/.claude/.env | cut -d= -f2`)

## Step 1: Scan the filesystem

Find all non-code files across these directories (excluding `node_modules/`, `.git/`, `dist/`, `build/`, `coverage/`):

- `/home/coder/.claude/commands/*.md`
- `/home/coder/.claude/skills/*/SKILL.md`
- `/websites/*/CLAUDE.md`
- `/home/coder/.claude/infrastructure.yml`
- `/home/coder/.claude/projects/-websites/memory/*.md`

Then scan ALL projects under `/websites/*/` for non-code files. Non-code means anything that is NOT:
- `.js`, `.mjs`, `.cjs` (JavaScript)
- `.css` (Stylesheets)
- `.html` (Templates)
- `.sql` (Migrations — but DO include standalone `.sql` documentation)
- `.sh` (Shell scripts)
- `.ts`, `.tsx`, `.jsx` (TypeScript)
- Binary files: `.png`, `.jpg`, `.gif`, `.ico`, `.svg`, `.woff`, `.ttf`, `.eot`, `.webp`, `.mp4`, `.pdf`
- Auto-generated: `package-lock.json`, `node_modules/**`, `.git/**`, `dist/**`, `build/**`, `coverage/**`, `.nyc_output/**`

Non-code files to track include: `.md`, `.yml`, `.yaml`, `.json` (except package-lock.json), `.toml`, `.txt`, `.env.example`, `Dockerfile*`, `docker-compose*`, `.dockerignore`, `.gitignore`, `.editorconfig`, `.prettierrc`, `.eslintrc*`, `tsconfig.json`, `LICENSE`, and any other non-code files found.

For each file, compute:
- SHA-256 hash: `sha256sum <file> | awk '{print $1}'`
- Line count: `wc -l < <file>`
- Size in bytes: `stat -c %s <file>`

## Step 2: Fetch approved baselines

```bash
psql "postgresql://urd:$(grep URD_PASSWORD /home/coder/.claude/.env | cut -d= -f2)@192.168.0.20:5439/config_db" \
  -t -A -F '|' \
  -c "SELECT file_path, content_hash, line_count, size_bytes, category, approved_at FROM doc_baselines ORDER BY file_path"
```

## Step 3: Compare and report

For each scanned file, classify it into one of these statuses:

| Status | Meaning |
|--------|---------|
| **APPROVED** | Hash matches baseline — no changes |
| **CHANGED** | File exists in baselines but hash differs — show line count delta and size delta |
| **NEW** | File exists on disk but has no baseline — never approved |
| **MISSING** | Baseline exists but file is gone from disk |

## Step 4: Output the report

Print a summary table grouped by status. For CHANGED and NEW files, highlight:
- Line count change (e.g., `+42 lines`, `-10 lines`)
- Size change (e.g., `+2.1 KB`)
- Category (command, skill, claude-md, config, memory, doc, other)
- Days since last approval (for CHANGED files)

Example format:
```
## Doc Audit Report — 2026-03-13

### NEW (unapproved files) — 3 files
| File | Lines | Size | Category |
|------|-------|------|----------|
| /websites/foo/README.md | 42 | 1.2 KB | doc |

### CHANGED (drift from baseline) — 2 files
| File | Lines | Delta | Size | Delta | Last Approved |
|------|-------|-------|------|-------|---------------|
| /home/coder/.claude/commands/develop.md | 541 | +12 | 16 KB | +0.5 KB | 5 days ago |

### MISSING (baseline exists, file gone) — 1 file
| File | Was | Last Approved |
|------|-----|---------------|
| /websites/old-thing/README.md | 20 lines, 0.8 KB | 10 days ago |

### APPROVED — 35 files (no changes)

Summary: 3 new, 2 changed, 1 missing, 35 approved
```

## Step 5: Suggest actions

- For NEW files: "Run `/doc-approve` to approve these files or delete if unneeded"
- For CHANGED files: "Review changes and run `/doc-approve` to update baselines, or revert if bloated"
- For MISSING files: "Clean up stale baselines with `/doc-approve --missing`"

If this is the FIRST run (no baselines exist), say so clearly and suggest running `/doc-approve --all` to establish the initial baseline.
