#!/usr/bin/env bash
#
# tmux-resurrect save-command strategy for claude panes.
#
# resurrect calls this once per pane with the pane's shell PID as $1 and records
# stdout as the pane's restore command (field 11 of the save file).
#
# For a pane running claude, we record `claude -r <sessionId>` so restore reopens
# the EXACT conversation (sessionId comes from ~/.claude/sessions/<claudePID>.json,
# which claude writes for every live process). For every non-claude pane we
# delegate to resurrect's default `ps` strategy, so their behavior is unchanged.
#
# Fallbacks: claude alive but sessionId unresolved -> `claude -r` (interactive
# picker). No claude child -> default strategy.

PANE_PID="$1"

RESURRECT_DIR="$HOME/.tmux/plugins/tmux-resurrect"
DEFAULT_STRATEGY="$RESURRECT_DIR/save_command_strategies/ps.sh"
SESSIONS_DIR="$HOME/.claude/sessions"

delegate_to_default() {
	exec "$DEFAULT_STRATEGY" "$PANE_PID"
}

main() {
	# no pid -> nothing we can do; let the default strategy handle it
	[ -z "$PANE_PID" ] && delegate_to_default

	# is a claude process running directly in this pane?
	local claude_pid
	claude_pid="$(pgrep -P "$PANE_PID" -x claude | head -1)"
	[ -z "$claude_pid" ] && delegate_to_default

	# claude is running: try to resolve its session id
	local session_file="$SESSIONS_DIR/${claude_pid}.json"
	local sid=""
	if [ -r "$session_file" ]; then
		sid="$(jq -r '.sessionId // empty' "$session_file" 2>/dev/null)"
	fi

	if [ -n "$sid" ]; then
		echo "claude -r $sid"
	else
		# claude alive but id unknown -> picker lets the user choose on restore
		echo "claude -r"
	fi
}
main
