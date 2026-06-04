# Claude Usage Log System

Cross-session token usage tracking with rolling averages.

## How It Works

### Live Logging (statusline-command.sh)

Every statusline render appends current session stats to:
```
~/.claude/usage-logs/live/session-{SESSION_ID}.jsonl
```

Each entry:
```json
{"ts":1780597943,"session":"abc123","input":43022,"output":1025,"cost":0.549940}
```

- `ts`: Unix timestamp
- `session`: Claude session ID
- `input`: Cumulative input tokens (this session)
- `output`: Cumulative output tokens (this session)
- `cost`: Cumulative cost in USD (this session)

### Daily Consolidation (usage-log-consolidate.sh)

Cron job runs daily at 00:01:
1. Finds live logs from yesterday (mtime >12h to avoid active sessions)
2. Extracts yesterday's entries
3. Consolidates into `~/.claude/usage-logs/archive/{YYYY-MM-DD}.jsonl`
4. Cleans up:
   - Live logs >14 days old
   - Archives >90 days old

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

- **Live logs**: ~100 bytes per render, retained 14 days (~2MB max)
- **Archives**: ~100KB per day, retained 90 days (~9MB max)
- **Total**: ~11MB max

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
- `~/.claude/usage-logs/live/*.jsonl`: Active session logs
- `~/.claude/usage-logs/archive/*.jsonl`: Historical daily logs

## Cron Setup

Already configured:
```cron
1 0 * * * /home/david.jefts/setup-files/claude/usage-log-consolidate.sh
```

Verify: `crontab -l`
