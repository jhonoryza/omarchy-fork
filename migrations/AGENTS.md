# Purpose

User migration scripts that run during `omarchy-migrate` to update configs, fix settings, and apply one-off changes when Omarchy updates.

# Ownership

- Migration file format and naming
- Migration execution order
- Migration creation tooling

# Local Contracts

- File permissions must be `0644` (`-rw-r--r--`); migrations are sourced, not executed directly
- No shebang line
- Start with an `echo` describing what the migration does
- Use `$OMARCHY_PATH` to reference the omarchy directory
- Prefer helper commands (`omarchy-cmd-present`, `omarchy-cmd-missing`, `omarchy-pkg-present`, `omarchy-pkg-missing`)

# Work Guidance

## Creating a migration

```bash
omarchy-dev-add-migration --no-edit
```

This creates a migration file named after the unix timestamp of the last commit.

## Migration format

```bash
echo "Short description of what this migration does"

if omarchy-cmd-missing some-command; then
  # perform migration logic
fi
```

## Exceptions

Migrations may use raw `pacman`, `command -v`, or direct config edits when needed for historical compatibility or one-off repair work.

Some older migrations predate these rules. Do not copy older migrations that start with shebangs, omit the leading `echo`, or hard-code `~/.local/share/omarchy`.

# Verification

No automated verification. Migrations are run during `omarchy-migrate` which is called from `install.sh`.