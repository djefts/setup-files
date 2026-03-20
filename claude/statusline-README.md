# Claude Code Statusline Setup

## Quick Start

1. **Place script**: Copy `statusline-command.sh` to `~/.claude/`
2. **Make executable**: `chmod +x ~/.claude/statusline-command.sh`
3. **Configure Claude Code**: Add to `~/.claude/settings.json`:
   ```json
   {
     "statusline": {
       "command": "$HOME/.claude/statusline-command.sh"
     }
   }
   ```

## Dependencies

**Required**: `perl`, `jq`, `bc`, `git`, `curl`, `awk`, `sed`

**Optional**: `docker` (container monitoring), `ss` (port monitoring)

## Jira Integration (Optional)

1. **Configure River MCP** in `~/.claude.json`:
   ```json
   {
     "mcpServers": {
       "river-mcp": {
         "url": "http://localhost:3000",
         "headers": {
           "JiraToken": "your-token",
           "ConfluenceToken": "your-token"
         }
       }
     }
   }
   ```

2. **Find your Jira custom field IDs**:
    - Story points: Usually `customfield_10106` (check your Jira API)
    - Sprint: Usually `customfield_10104`
    - Update lines 238, 260, 264 in the script if different

3. **Set primary branch** (line 493): Default is `dev`, change if needed

## Customization

Feel free to add your own customizations. Claude Code mostly understands how the statusline works and how to code Bash.
If you use CC to update this then I highly recommend telling it to use the built-in `statusline` skill/agent for the
vast majority of changes.

## Disclaimer

I used Claude Code to do the first 90% of this and then fixed the last few things myself and make the code not slop.
