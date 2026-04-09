# Bash Commands

Custom bash functions and utilities sourced on shell startup.

## How It Works

`global.bashrc` sources every file in this directory:
```bash
for f in ~/setup-files/bash_commands/*; do
  source "$f"
done
```

## What Goes Here

- Custom bash functions
- Utility scripts that need to run in the current shell context
- Terminal title updaters
- Prompt customizations
- Shell helpers

## File Organization

Each file typically contains related functions grouped by purpose.

## Adding New Commands

1. Create file in this directory (no `.sh` extension needed)
2. Make it executable: `chmod +x filename`
3. Next shell startup will auto-source it
4. Functions are immediately available in all new terminals
