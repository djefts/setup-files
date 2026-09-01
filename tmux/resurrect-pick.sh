#!/usr/bin/env bash
#
# Interactive picker for a tmux-resurrect save to restore.
#
# resurrect always restores whatever `last` points at. This script builds a
# native `tmux display-menu` listing the timestamped save files (newest first);
# picking one repoints `last` at it and fires resurrect's restore. A tmux menu
# (vs a read-loop in a popup) gets us ESC/q-to-cancel and keyboard selection for
# free, and runs restore from a normal client context rather than inside a popup.
#
# Bind with:  bind R run-shell "~/setup-files/tmux/resurrect-pick.sh"
#
# Note: continuum autosave rewrites `last` every interval, so the relink is only
# "sticky" until the next save -- fine, we restore immediately after relinking.

set -euo pipefail

RESURRECT_DIR="$HOME/.local/share/tmux/resurrect"
RESTORE_SH="$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
SHOW=25                       # how many recent saves to list
KEYS="123456789abcdefghijklmnop"   # mnemonic keys, one per listed save (<= SHOW)

die() { tmux display-message "resurrect-pick: $1"; exit 1; }

[ -d "$RESURRECT_DIR" ] || die "no resurrect dir: $RESURRECT_DIR"
cd "$RESURRECT_DIR"

# newest-first, non-empty saves only
mapfile -t files < <(ls -1t tmux_resurrect_*.txt 2>/dev/null | while read -r f; do
	[ -s "$f" ] && echo "$f"
done | head -n "$SHOW")

[ "${#files[@]}" -gt 0 ] || die "no non-empty saves in $RESURRECT_DIR"

current="$(readlink last 2>/dev/null || true)"

# Build the display-menu argument list: repeating (label, key, command) triples.
menu=(display-menu -x C -y C -T "#[align=centre]pick a resurrect save to restore")
i=0
for f in "${files[@]}"; do
	[ "$i" -ge "${#KEYS}" ] && break
	key="${KEYS:$i:1}"

	# tmux_resurrect_20260827T160421.txt -> 2026-08-27 16:04
	ts="${f#tmux_resurrect_}"; ts="${ts%.txt}"
	human="${ts:0:4}-${ts:4:2}-${ts:6:2} ${ts:9:2}:${ts:11:2}"
	panes="$(grep -c '^pane' "$f" 2>/dev/null || echo 0)"
	wins="$(awk '/^window/{print $2}' "$f" 2>/dev/null | sort -u | wc -l)"
	mark=" "; [ "$f" = "$current" ] && mark="*"
	label="$(printf '%s %s  %sw %sp' "$mark" "$human" "$wins" "$panes")"

	# On select: relink `last` (relative symlink, so cd first) then restore in bg.
	cmd="run-shell -b 'cd \"$RESURRECT_DIR\" && ln -sf \"$f\" last && \"$RESTORE_SH\"'"

	menu+=("$label" "$key" "$cmd")
	i=$((i + 1))
done

tmux "${menu[@]}"
