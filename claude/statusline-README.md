# Claude Code Statusline Setup

A comprehensive statusline script for [Claude Code](https://claude.com/claude-code) that displays workspace, git, context window, session stats, Jira sprint progress, services, and system metrics in a beautiful boxed display.

## What is This?

This is a custom statusline script that extends Claude Code (Anthropic's official CLI tool) with rich contextual information displayed after each assistant response. It shows you everything from git status and context window usage to Jira sprint burndown and system resources—all in one place.

## Quick Start

1. **Copy the script**: Copy `statusline-command.sh` from this repository to `~/.claude/`
   ```bash
   cp statusline-command.sh ~/.claude/statusline-command.sh
   ```

2. **Make executable**:
   ```bash
   chmod +x ~/.claude/statusline-command.sh
   ```

3. **Configure Claude Code**: Add to `~/.claude/settings.json`:
   ```json
   {
     "statusline": {
       "command": "$HOME/.claude/statusline-command.sh"
     }
   }
   ```

4. **Verify it works**: Restart Claude Code or start a new session, then send any message. You should see a boxed statusline display after Claude's response.

## Dependencies

### Required
These commands must be available in your PATH:
- `perl` - Unicode handling for emoji width calculations
- `jq` - JSON parsing
- `bc` - Floating-point math
- `git` - Repository status
- `curl` - Jira API calls
- `awk` - Text processing
- `sed` - Text processing

Install on Ubuntu/Debian:
```bash
sudo apt install perl jq bc git curl gawk sed
```

Install on macOS:
```bash
brew install perl jq bc git curl gawk gnu-sed
```

### Optional
- `docker` - For container monitoring
- `ss` - For port monitoring (usually pre-installed on Linux; use `netstat` alternative on macOS)

## Jira Integration (Optional)

The statusline includes a Jira sprint progress tracker that shows ticket counts, story points, and burndown status.

### 1. Set up River MCP Server

River MCP is a Model Context Protocol server that provides Jira/Confluence access. The River MCP server is hosted by Firefly IT.

Follow the complete setup guide on the [River MCP Confluence page](https://confluence.fireflyspace.us/spaces/IT/pages/532697913/River+MCP#RiverMCP-RiverJira%26ConfluenceIntegrationSetup(MCP)) to get the server URL and configuration details.

### 2. Generate Jira API Tokens

Follow the token generation instructions in the [River MCP setup guide](https://confluence.fireflyspace.us/spaces/IT/pages/532697913/River+MCP#RiverMCP-RiverJira%26ConfluenceIntegrationSetup(MCP)), or generate them directly:

1. Go to your Atlassian account settings: https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a name (e.g., "Claude Code Statusline") and copy the token
4. Repeat for Confluence if you want Confluence support (optional for statusline)

### 3. Configure MCP in Claude Code

Add to `~/.claude.json`:
```json
{
  "mcpServers": {
    "river-mcp": {
      "url": "http://localhost:3000",
      "headers": {
        "JiraToken": "YOUR_JIRA_TOKEN_HERE",
        "ConfluenceToken": "YOUR_CONFLUENCE_TOKEN_HERE"
      }
    }
  }
}
```

### 4. Find Your Jira Custom Field IDs

Jira uses custom field IDs that vary by instance. To find yours:

1. Open your Jira in a browser
2. Navigate to any issue with story points and sprint information
3. Open browser DevTools (F12) → Network tab
4. Refresh the page and look for the API call to `/rest/api/3/issue/YOUR-ISSUE-KEY`
5. In the response, search for "story" or "sprint" to find field names like `customfield_10106`

Common defaults (but verify for your instance):
- Story points: `customfield_10106`
- Sprint: `customfield_10104`

If your IDs differ, update the script at:
- Line 238: `fields` parameter in the API call
- Line 260: Story points field in parsing
- Line 264: Sprint field in parsing

### 5. Set Your Primary Branch

If your team uses a branch other than `dev` for comparison:
- Edit line 452 in the script
- Change `"dev"` to your primary branch name (e.g., `"main"`, `"master"`, `"develop"`)

## Example Output

After each Claude response, you'll see a boxed display with comprehensive information:

```
╔═════════════════════════════════════════════════════════════════════════════════════╗  
║ 📁 CWD: ~/GLOW/gs-ghost/                                                            ║
║ 🌿 feature::use-dynamic-spacecraft-id (SD-16747) s:0 m:23 | origin/dev ↗️ 7         ║                                               
║ 🧠 Context: ●●○○○○○○○○ 24%  |  💾 User: 107 + Cache: 47.5K = Total: 47.6K           ║                                               
║ 💸 Session: 246.6K tok · $15.16 · 2h 43m · +183/-50 lines  |  90.3K/hr · $5.55/hr   ║                                               
╠═════════════════════════════════════════════════════════════════════════════════════╣                                               
║ 🤖 Model: us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0 (2.1.85)                 ║                                               
║ 🧩 Thinking: N/A  |  Reasoning: N/A  |  🎨 Style: default                           ║                                               
║ 🎫 Jira: tickets: 2 → 2 → 0 → 2 · 🛑 3  |  6/26pts · -6.7d left · 🚨 SPRINT AT RISK ║                                               
║ 🐳 Services: 1 containers  |  🔌 2 service ports active                             ║                                               
║ 🖥️  CPU 4.0% ○○○○○○○○○○  |  MEM 43.9% ●●●●○○○○○○  |  DISK 6% ●○○○○○○○○○             ║                                               
╚═════════════════════════════════════════════════════════════════════════════════════╝
```

**What each line shows:**
- **Line 1**: Current working directory (and project dir if different)
- **Line 2**: Git branch formatted as `type::description (TICKET)`, file changes (s=staged, m=modified, u=untracked), and commits ahead/behind your primary branch (`origin/dev` by default)
- **Line 3**: Context window usage percentage with visual progress bar, plus breakdown of User tokens + Cache tokens = Total
- **Line 4**: Session totals - tokens used, cost in USD, elapsed time, lines of code added/removed, and hourly rates
- **Line 5**: Model name and Claude Code version
- **Line 6**: Extended thinking mode, reasoning effort level, and output style setting
- **Line 7**: Jira sprint workflow (todo → in progress → in review → done · blocked), story points completed/total, days ahead/behind schedule, and burndown status (🚀 ahead, 🎯 on track, 🚨 at risk, etc.)
- **Line 8**: Running Docker containers and active service ports in development range (3000-19999)
- **Line 9**: System resources with color-coded progress bars (green <33%, yellow 33-66%, red >66%)

## Troubleshooting

### Statusline not appearing
- Ensure the script is executable: `ls -la ~/.claude/statusline-command.sh` should show `x` permissions
- Check `~/.claude/settings.json` has the correct path with no typos
- Restart Claude Code completely
- Test the script manually: `echo '{}' | ~/.claude/statusline-command.sh` should produce output

### Jira data showing N/A or errors
- Verify River MCP server is running: `curl http://localhost:3000` should respond
- Check your tokens are correct in `~/.claude.json`
- Verify you have Jira issues assigned to you in an active sprint
- Check cache file for errors: `cat /tmp/claude-statusline-cache/first-issue.json`

### Missing dependencies
- Run `which perl jq bc git curl awk sed` to check which commands are missing
- Install missing dependencies using your package manager

### Width/alignment issues
- Check debug logs: `cat /tmp/claude-statusline-cache/width-debug.log`
- Ensure your terminal supports Unicode/emoji (most modern terminals do)
- If using tmux/screen, ensure UTF-8 is enabled

### Line numbers don't match
- The README references line numbers that may shift if you modify the script
- Search for the actual text instead (e.g., search for `"dev"` or `customfield_10106`)

## Customization

Feel free to modify the script for your needs:
- Add new metrics or data sources
- Change colors (see the `COLORS` section at the top)
- Modify the layout or add/remove lines
- Adjust thresholds for progress bars

If you use Claude Code to modify this script, use the `/statusline` skill if available—it understands the script structure and can help maintain code quality.

## Disclaimer

This script was initially created with Claude Code's assistance, then refined and debugged manually to remove unnecessary complexity and ensure reliability.