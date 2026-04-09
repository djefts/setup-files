# Setup Files

Portable dotfiles and system configurations synchronized across machines via GitHub.

## Architecture

This repository follows a **copy-on-startup** pattern:
- Config files live in `~/setup-files/` (version controlled)
- On each terminal startup, `global.bashrc` copies files to their expected locations
- Edit once in `~/setup-files/`, deploy everywhere automatically

## How It Works

1. **Shell startup**: `~/.bashrc` sources `~/setup-files/global.bashrc`
2. **File sync**: `global.bashrc` copies `default_files/` to `~`
3. **Git config**: Includes `global.gitconfig` without overwriting local settings
4. **Environment setup**: Loads aliases, Node environment, bash history sharing
5. **Custom commands**: Sources all scripts from `bash_commands/`
6. **Validation**: Checks that expected crontab entries are installed

## Directory Structure

- **`default_files/`** — Config files copied to `~` on startup (`.bashrc`, `.vimrc`, etc)
- **`bash_commands/`** — Custom bash functions and utilities
- **`claude/`** — Claude Code customizations (statusline, settings)
- **`cron-scripts/`** — Scripts for cron jobs with automatic validation
- **Root level** — Global configs sourced but not copied (`global.bashrc`, `global.gitconfig`)

See README in each directory for details.

## Usage

### First-time setup on a new machine:
```bash
cd ~
git clone <repo-url> setup-files
echo "source ~/setup-files/global.bashrc" >> ~/.bashrc
source ~/.bashrc
```

### Making changes:
1. Edit files in `~/setup-files/`
2. Commit and push to sync across machines
3. Changes apply automatically on next shell startup

### Adding cron scripts:
1. Create script in `cron-scripts/`
2. Add `# CRONTAB: <schedule> <path>` comment to script
3. Run `crontab -e` and add the line (validator will warn if missing)

## Important Rules

- **Never edit files directly in `~`** — they get overwritten on next startup
- **Always edit in `~/setup-files/`** — this is the source of truth
- Config files in `default_files/` are **replaced** on startup (use for full configs)
- Config files at root level are **included** (use for partial/global configs)
