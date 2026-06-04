# Claude Usage Log System

Cross-session token usage tracking with rolling averages.

## How It Works

### Live Logging (statusline-command.sh)

Every statusline render appends current session stats to:
```
~/.claude/usage-logs/live/session-{SESSION_ID}.dat
```

Each entry (space-separated):
```
1780597943 abc123-uuid-here 43022 1025 0.549940
```

Format: `timestamp session_id input_tokens output_tokens cost`

- `timestamp`: Unix timestamp (seconds)
- `session_id`: Claude session UUID
- `input_tokens`: Cumulative input tokens (this session)
- `output_tokens`: Cumulative output tokens (this session)
- `cost`: Cumulative cost in USD (this session)

### Daily Consolidation (usage-log-consolidate.sh)

Cron job runs daily at 12:01 PM:
1. **Consolidates last 5 days** (catches missed weekend runs)
2. For each day 1-5 days ago:
   - Skip if archive already exists (idempotent)
   - Extract that day's entries from all live files
   - Create `~/.claude/usage-logs/archive/{YYYY-MM-DD}.dat`
3. Cleans up:
   - Live logs >7 days old (reduced from 14, since consolidating more aggressively)
   - Archives >90 days old

**Benefits:**
- Misses Friday → runs Monday, catches Fri/Sat/Sun
- Idempotent: safe to run multiple times
- `ls archive/` shows exactly what's consolidated (gaps = missed days)

### Statusline Display

Model line shows rolling averages:
```
🤖 Model: Sonnet 4.5 (v1.2.3) | Avg: 24h: 12.5K/hr ($0.15) · 7d: 8.3K/hr ($0.10)
```

Calculation:
- Read all live logs + last 7 days of archives
- Filter by timestamp (24h / 7d windows)
- Sum tokens and cost
- Divide by hours (24 or 168)

## Storage

- **Live logs**: ~100 bytes per render, retained 7 days (~1MB max)
- **Archives**: ~100KB per day, retained 90 days (~9MB max)
- **Total**: ~10MB max

## Performance

- Log append: +0.1ms per statusline render
- Average calculation: +2-5ms per statusline render
- Imperceptible overhead

## Future Enhancements

### Subagent Token Tracking

Currently only tracks main loop tokens. To include subagent usage:

1. Parse transcript files in consolidation script:
   ```bash
   find ~/.claude/sessions/*/transcript.jsonl -mtime -1 -exec grep -h "Agent\|Workflow" {} \;
   ```

2. Extract token counts from agent completions

3. Append to archive file

Not implemented yet - adds complexity, transcripts large.

## Files

- `statusline-command.sh`: Appends live logs, calculates averages, displays
- `usage-log-consolidate.sh`: Daily cron job for archival
- `~/.claude/usage-logs/live/*.dat`: Active session logs (space-separated)
- `~/.claude/usage-logs/archive/*.dat`: Historical daily logs (space-separated)

## Cron Setup

Already configured:
```cron
1 12 * * * /home/david.jefts/setup-files/claude/usage-log-consolidate.sh
```

Runs at 12:01 PM daily (middle of work hours, laptop likely awake).

Verify: `crontab -l`
