# Doc Approve — Approve current file versions as baselines

You are approving non-code files by saving their current state to `config_db.doc_baselines`.

**Database connection:** `postgresql://urd:<password>@192.168.0.20:5439/config_db`
(Get password from: `grep URD_PASSWORD /home/coder/.claude/.env | cut -d= -f2`)

Store the connection string in a variable for reuse:
```bash
CONFIG_DB="postgresql://urd:$(grep URD_PASSWORD /home/coder/.claude/.env | cut -d= -f2)@192.168.0.20:5439/config_db"
```

## Arguments

The user may provide arguments after the command:
- `/doc-approve` — interactive: show unapproved/changed files and ask which to approve
- `/doc-approve --all` — approve ALL scanned non-code files (useful for initial baseline)
- `/doc-approve <path>` — approve a specific file
- `/doc-approve --missing` — clean up baselines for files that no longer exist on disk
- `/doc-approve --category <cat>` — approve all files in a category (command, skill, claude-md, config, memory, doc, other)

## File categories

Assign categories automatically based on path:
- `/home/coder/.claude/commands/*.md` → `command`
- `/home/coder/.claude/skills/*/SKILL.md` → `skill`
- `/websites/*/CLAUDE.md` → `claude-md`
- `/home/coder/.claude/infrastructure.yml` → `config`
- `/home/coder/.claude/projects/-websites/memory/*.md` → `memory`
- `Dockerfile*`, `docker-compose*`, `.env*`, `*.json` (configs) → `config`
- All other `.md` files → `doc`
- Everything else → `other`

## How to approve a file

For each file to approve:

1. Read the file content
2. Compute hash, line count, and size:
```bash
sha256sum <file> | awk '{print $1}'
wc -l < <file>
stat -c %s <file>
```

3. Upsert the baseline via psql. Use a prepared-style approach to handle content with special characters:
```bash
psql "$CONFIG_DB" -c "
  INSERT INTO doc_baselines (file_path, content_hash, line_count, size_bytes, content, category, approved_by)
  VALUES (\$\$<file_path>\$\$, '<sha256>', <lines>, <bytes>, \$\$<content>\$\$, '<category>', 'claude')
  ON CONFLICT (file_path) DO UPDATE SET
    content_hash = EXCLUDED.content_hash,
    line_count = EXCLUDED.line_count,
    size_bytes = EXCLUDED.size_bytes,
    content = EXCLUDED.content,
    category = EXCLUDED.category,
    approved_at = NOW(),
    approved_by = EXCLUDED.approved_by
"
```

**Important:** Use dollar-quoting (`$$`) for file_path and content to safely handle special characters in file contents.

## For `--missing` mode

Query baselines and check which files no longer exist on disk:
```bash
psql "$CONFIG_DB" -t -A -c "SELECT id, file_path FROM doc_baselines ORDER BY file_path"
```

For each file path, check if it exists. If not, confirm with the user then delete:
```bash
psql "$CONFIG_DB" -c "DELETE FROM doc_baselines WHERE id = <id>"
```

## For interactive mode (no arguments)

1. Run the same scan as `/doc-audit` to find NEW and CHANGED files
2. List them and ask the user: "Which files should I approve? (all / list numbers / skip)"
3. Approve selected files
4. Report what was approved

## For `--all` mode

Scan all non-code files (same scan logic as `/doc-audit`), approve each one without prompting.

## Output

After approving, print a summary:
```
Approved 12 files:
- 6 commands
- 3 skills
- 2 claude-md
- 1 config

Baselines are now up to date.
```
