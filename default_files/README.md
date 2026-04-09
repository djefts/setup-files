# Default Files

Config files that get **copied** to `~` on every shell startup.

## Behavior

On each terminal startup, `global.bashrc` runs:
```bash
cp -a --remove-destination ~/setup-files/default_files/. -t ~/
```

This overwrites files in `~` with the versions here.

## What Goes Here

Files that should be:
- **Completely controlled** by this repo (no local edits)
- **User-specific** (like `.bashrc`, `.vimrc`)
- **Standalone** configs that don't need to merge with system defaults

## What Doesn't Go Here

- Files that need to preserve local customizations
- Files that should be merged/included (use root-level files instead)
- System-wide configs (put in `/etc/`)

## Important

**Never edit these files directly in `~`** — changes will be lost on next shell startup.
Always edit in `~/setup-files/default_files/`.
