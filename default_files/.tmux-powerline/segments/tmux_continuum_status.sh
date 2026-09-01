# shellcheck shell=bash
# Overlay override for tmux-powerline's built-in tmux_continuum_status segment.
# Instead of just echoing the configured save interval (a static number that
# never changes), this shows how long ago continuum last saved, read straight
# from continuum's own "@continuum-save-last-timestamp" option — no separate
# bookkeeping of our own. Lives in the user overlay dir so plugin updates to
# either tmux-powerline or tmux-continuum won't clobber it.

# shellcheck source=lib/util.sh
source "${TMUX_POWERLINE_DIR_LIB}/util.sh"

if [[ -n "$TMUX_PLUGIN_MANAGER_PATH" ]]; then
	TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH_DEFAULT="${TMUX_PLUGIN_MANAGER_PATH}/tmux-continuum"
elif [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/tmux" ]]; then
	TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH_DEFAULT="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins/tmux-continuum"
else
	TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH_DEFAULT="${HOME}/.tmux/plugins/tmux-continuum"
fi
TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX_DEFAULT="saved "

generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Path to the tmux-continuum git repo.
export TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH="${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH_DEFAULT}"
# Message to prefix the "N ago" indication with.
export TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX="$TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX_DEFAULT"
EORC
	echo "$rccontents"
}

run_segment() {
	__process_settings

	# Pull option names + get_tmux_option straight from continuum, so we track
	# exactly what the plugin tracks (no ad-hoc timestamp of our own).
	if [ ! -r "${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH}/scripts/variables.sh" ]; then
		return 0
	fi
	source "${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH}/scripts/helpers.sh"
	source "${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH}/scripts/variables.sh"

	# Autosave disabled? Mirror continuum's own "off" state.
	local save_int
	save_int="$(get_tmux_option "$auto_save_interval_option" "$auto_save_interval_default")"
	if [ "$save_int" -le 0 ] 2>/dev/null; then
		echo "continuum off"
		return 0
	fi

	# Prefer the mtime of the REAL save file (the "last" symlink's target) over
	# continuum's @continuum-save-last-timestamp option. That option is stamped to
	# "now" on first plugin load WITHOUT an actual save (continuum.tmux's
	# delay_saving_environment_on_first_plugin_load), so keying off it makes a
	# freshly-attached server falsely read "saved just now". The file mtime only
	# advances on a genuine save, so it's honest across reboots. Fall back to the
	# option only if we can't resolve the save file.
	local resurrect_dir last=""
	resurrect_dir="$(get_tmux_option "@resurrect-dir" "")"
	if [ -z "$resurrect_dir" ]; then
		if [ -d "$HOME/.tmux/resurrect" ]; then
			resurrect_dir="$HOME/.tmux/resurrect"
		else
			resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
		fi
	fi
	# expand ~, $HOME, $HOSTNAME the same way resurrect does
	resurrect_dir="$(echo "$resurrect_dir" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,~,$HOME,g")"

	if [ -e "${resurrect_dir}/last" ]; then
		# -L follows the symlink to the target file's real write time
		last="$(stat -L -c %Y "${resurrect_dir}/last" 2>/dev/null)"
	fi
	# fall back to continuum's option only if the file is unavailable
	if [ -z "$last" ]; then
		last="$(get_tmux_option "$last_auto_save_option" "")"
	fi
	if [ -z "$last" ]; then
		echo "${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX}never"
		return 0
	fi

	local now mins
	now="$(date +%s)"
	mins=$(( (now - last) / 60 ))
	if [ "$mins" -le 0 ]; then
		echo "${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX}just now"
	else
		echo "${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX}${mins}m ago"
	fi
	return 0
}

__process_settings() {
	if [ -z "$TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH" ]; then
		export TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH="${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PATH_DEFAULT}"
	fi
	if [ -z "$TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX" ]; then
		export TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX="${TMUX_POWERLINE_SEG_TMUX_CONTINUUM_PREFIX_DEFAULT}"
	fi
}
