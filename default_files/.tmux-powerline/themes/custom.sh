# shellcheck shell=bash
# Custom Theme - similar to dracula

if tp_patched_font_in_use; then
	TMUX_POWERLINE_SEPARATOR_LEFT_BOLD=""
	TMUX_POWERLINE_SEPARATOR_LEFT_THIN=""
	TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD=""
	TMUX_POWERLINE_SEPARATOR_RIGHT_THIN=""
else
	TMUX_POWERLINE_SEPARATOR_LEFT_BOLD="◀"
	TMUX_POWERLINE_SEPARATOR_LEFT_THIN="❮"
	TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD="▶"
	TMUX_POWERLINE_SEPARATOR_RIGHT_THIN="❯"
fi

# Firefly colors
TMUX_POWERLINE_DEFAULT_BACKGROUND_COLOR='#3f3f3f'
TMUX_POWERLINE_DEFAULT_FOREGROUND_COLOR='#ffffff'

TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_RIGHT_BOLD}
TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR=${TMUX_POWERLINE_DEFAULT_RIGHTSIDE_SEPARATOR:-$TMUX_POWERLINE_SEPARATOR_LEFT_BOLD}

# Window status format
if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_CURRENT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_CURRENT=(
		"#[fg=#297050,bg=#d0df00]"
		"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"
		"#[bg=#d0df00,fg=#3f3f3f,bold]"
		" #I#F "
		"$TMUX_POWERLINE_SEPARATOR_RIGHT_THIN"
		" #W "
		"#[fg=#d0df00,bg=#297050]"
		"$TMUX_POWERLINE_DEFAULT_LEFTSIDE_SEPARATOR"
	)
fi

if [ -z "$TMUX_POWERLINE_WINDOW_STATUS_FORMAT" ]; then
	TMUX_POWERLINE_WINDOW_STATUS_FORMAT=(
		"#[bg=#297050,fg=#ffffff]"
		"  #I#{?window_flags,#F, } "
		"$TMUX_POWERLINE_SEPARATOR_RIGHT_THIN"
		" #W "
	)
fi

# LEFT SIDE: session, git, continuum, sync-panes
if [ -z "$TMUX_POWERLINE_LEFT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_LEFT_STATUS_SEGMENTS=(
		"tmux_session_info #0075de #ffffff"
		"vcs_branch #f5791c #000000"
		"tmux_continuum_status #f5332a #ffffff"
	)
fi

# RIGHT SIDE: network, weather, date/time
if [ -z "$TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS" ]; then
	TMUX_POWERLINE_RIGHT_STATUS_SEGMENTS=(
		"ifstat_sys #a81b8d #ffffff"
		"wan_ip #a81b8d #ffffff"
		"weather_city #8be9fd #3f3f3f"
		"weather #8be9fd #3f3f3f default_separator no_sep_bg_color no_sep_fg_color no_spacing_disable separator_disable"
		"date #3f3f3f #ffffff"
		"time #3f3f3f #ffffff ${TMUX_POWERLINE_SEPARATOR_LEFT_THIN} no_sep_bg_color no_sep_fg_color no_spacing_disable separator_disable"
	)
fi
