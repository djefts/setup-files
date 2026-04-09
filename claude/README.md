# Claude Code Customizations

Configuration and customizations for Claude Code CLI.

## Contents

- **`statusline.sh`** — Custom statusline showing git info, Jira ticket, and metrics
- **Other customizations** — Settings, hooks, and project-specific configs

## Integration

Claude Code automatically picks up configs from:
- `~/.claude/` (user-global)
- `<project>/.claude/` (project-specific)

This directory serves as the source for configs that get deployed via the setup-files workflow.

## Statusline

The custom statusline displays:
- Current git branch and status
- Jira ticket if branch follows naming convention
- Token usage and model info
- Cached/non-cached tokens

See `statusline.sh` for implementation details.
