#!/usr/bin/env bash

# Daily cron job to consolidate usage logs
# Run at 00:01 daily: 1 0 * * * ~/.claude/usage-log-consolidate.sh

USAGE_LOG_DIR="$HOME/.claude/usage-logs"
LIVE_DIR="$USAGE_LOG_DIR/live"
ARCHIVE_DIR="$USAGE_LOG_DIR/archive"

mkdir -p "$ARCHIVE_DIR" 2>/dev/null

# Get yesterday's date
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null)
ARCHIVE_FILE="$ARCHIVE_DIR/${YESTERDAY}.jsonl"

# Find and consolidate all live logs from yesterday
# Use mtime check: files modified >12 hours ago (to avoid active sessions)
if [[ -d "$LIVE_DIR" ]]; then
    find "$LIVE_DIR" -name "*.jsonl" -type f -mmin +720 -print0 2>/dev/null | while IFS= read -r -d '' logfile; do
        # Extract entries from yesterday only
        YESTERDAY_START=$(date -d "$YESTERDAY 00:00:00" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$YESTERDAY 00:00:00" +%s 2>/dev/null)
        YESTERDAY_END=$(date -d "$YESTERDAY 23:59:59" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$YESTERDAY 23:59:59" +%s 2>/dev/null)

        awk -v start="$YESTERDAY_START" -v end="$YESTERDAY_END" '
        {
            match($0, /"ts":([0-9]+)/, ts_match)
            ts = ts_match[1]
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
    fi
fi

# Clean up old live session logs (>14 days)
find "$LIVE_DIR" -name "*.jsonl" -type f -mtime +14 -delete 2>/dev/null

# Clean up old archives (>90 days)
find "$ARCHIVE_DIR" -name "*.jsonl" -type f -mtime +90 -delete 2>/dev/null

# Optional: Parse transcripts for subagent tokens (future enhancement)
# This would grep through ~/.claude/sessions/*/transcript.jsonl for Agent/Workflow completions
# and extract their token usage, appending to the archive file
