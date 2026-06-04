#!/usr/bin/env bash

# Daily cron job to consolidate usage logs
# Run at 12:01 PM daily: 1 12 * * * ~/.claude/usage-log-consolidate.sh
#
# Consolidates the last 5 days (catches missed weekend runs)
# Idempotent: skips days that already have archives

USAGE_LOG_DIR="$HOME/.claude/usage-logs"
LIVE_DIR="$USAGE_LOG_DIR/live"
ARCHIVE_DIR="$USAGE_LOG_DIR/archive"

mkdir -p "$ARCHIVE_DIR" 2>/dev/null

# Consolidate last 5 days (catches weekends + missed runs)
for days_ago in {1..5}; do
    # Get date for N days ago
    if date -d "yesterday" >/dev/null 2>&1; then
        # GNU date (Linux)
        TARGET_DATE=$(date -d "$days_ago days ago" +%Y-%m-%d)
        DAY_START=$(date -d "$TARGET_DATE 00:00:00" +%s)
        DAY_END=$(date -d "$TARGET_DATE 23:59:59" +%s)
    else
        # BSD date (macOS)
        TARGET_DATE=$(date -v-${days_ago}d +%Y-%m-%d)
        DAY_START=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TARGET_DATE 00:00:00" +%s)
        DAY_END=$(date -j -f "%Y-%m-%d %H:%M:%S" "$TARGET_DATE 23:59:59" +%s)
    fi

    ARCHIVE_FILE="$ARCHIVE_DIR/${TARGET_DATE}.dat"

    # Skip if archive already exists (idempotent)
    if [[ -f "$ARCHIVE_FILE" ]]; then
        continue
    fi

    echo "Consolidating $TARGET_DATE..."

    # Extract entries from this day across all live files
    if [[ -d "$LIVE_DIR" ]]; then
        find "$LIVE_DIR" -name "*.dat" -type f 2>/dev/null | while IFS= read -r logfile; do
            awk -v start="$DAY_START" -v end="$DAY_END" '
            {
                ts = $1
                if (ts >= start && ts <= end) {
                    print $0
                }
            }
            ' "$logfile" >> "$ARCHIVE_FILE.tmp"
        done

        # Sort and dedupe the consolidated file
        if [[ -f "$ARCHIVE_FILE.tmp" ]]; then
            sort -u "$ARCHIVE_FILE.tmp" > "$ARCHIVE_FILE"
            rm "$ARCHIVE_FILE.tmp"
            echo "Created archive: $ARCHIVE_FILE ($(wc -l < "$ARCHIVE_FILE") entries)"
        fi
    fi
done

# Clean up old live session logs (>7 days, reduced from 14 since consolidating more aggressively)
DELETED=$(find "$LIVE_DIR" -name "*.dat" -type f -mtime +7 -delete -print 2>/dev/null | wc -l)
[[ "$DELETED" -gt 0 ]] && echo "Cleaned up $DELETED old live session files"

# Note: Archive cleanup disabled to preserve long-term historical data for trends

# Optional: Parse transcripts for subagent tokens (future enhancement)
# This would grep through ~/.claude/sessions/*/transcript.jsonl for Agent/Workflow completions
# and extract their token usage, appending to the archive file
