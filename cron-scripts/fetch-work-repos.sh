#!/bin/bash
# Fetch all work repos in ~/GLOW/ quietly
# Runs via cron during work hours
#
# CRONTAB: 0 11-15 * * 1-5 ~/setup-files/cron-scripts/fetch-work-repos.sh

GLOW_DIR="$HOME/GLOW"
LOG_FILE="$HOME/.local/log/git-fetch.log"

# Make sure log dir exists
mkdir -p "$(dirname "$LOG_FILE")"

# Find all .git directories and fetch
find "$GLOW_DIR" -maxdepth 2 -type d -name .git 2>/dev/null | while read -r gitdir; do
    repo_dir="$(dirname "$gitdir")"
    repo_name="$(basename "$repo_dir")"

    # Fetch quietly, log only if error
    if ! git -C "$repo_dir" fetch --quiet --all 2>/dev/null; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to fetch: $repo_name" >> "$LOG_FILE"
    fi
done
