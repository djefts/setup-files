# Cron Scripts

Scripts intended to run via system cron, with automatic validation.

## How It Works

1. Each script includes a `# CRONTAB:` comment documenting expected schedule
2. On shell startup, `global.bashrc` checks if entries exist in actual crontab
3. Automatically adds missing entries to your crontab

## Adding a New Cron Script

1. Create script in this directory
2. Make it executable: `chmod +x script-name.sh`
3. Add this comment near the top:
   ```bash
   # CRONTAB: 0 9 * * * ~/setup-files/cron-scripts/script-name.sh
   ```
4. Next shell startup will automatically add it to crontab

## Scripts

### `fetch-work-repos.sh`
Fetches all git repos in `~/GLOW/` quietly during work hours (11am-3pm weekdays).
Logs errors to `~/.local/log/git-fetch.log`.
