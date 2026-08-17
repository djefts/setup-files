# shellcheck shell=bash
# Location label shown next to the weather segment so the temperature has a
# place attached to it.
#
# TMUX_POWERLINE_SEG_WEATHER_CITY:
#   "auto" (or unset) -> detect the city name via GeoIP (ipapi.co / ipinfo.io),
#                        cached ~24h; tracks the same location that "auto"
#                        lat/lon uses for the weather segment.
#   any other value   -> shown verbatim (e.g. "Georgetown", "78613").
#
# On "auto", the network fetch runs in a detached background process and the
# cached value is returned immediately, so tmux rendering is never blocked
# (mirrors the weather.sh segment's approach).

TMUX_POWERLINE_SEG_WEATHER_CITY_DEFAULT="auto"
# How often to re-detect the city (seconds). Defaults to the weather segment's
# location update period so the two stay in sync (24h).
TMUX_POWERLINE_SEG_WEATHER_CITY_UPDATE_PERIOD="${TMUX_POWERLINE_SEG_WEATHER_LOCATION_UPDATE_PERIOD:-86400}"
TMUX_POWERLINE_SEG_WEATHER_CITY_CACHE_FILE="${TMUX_POWERLINE_DIR_TEMPORARY}/weather_city_cache.txt"

run_segment() {
	local city="${TMUX_POWERLINE_SEG_WEATHER_CITY:-$TMUX_POWERLINE_SEG_WEATHER_CITY_DEFAULT}"

	# Static override: any non-"auto" value is shown as-is.
	if [ "$city" != "auto" ]; then
		echo "📍 ${city}"
		return 0
	fi

	# Auto: return the cached city immediately (even if stale), refresh in background.
	local cached=""
	if [ -f "$TMUX_POWERLINE_SEG_WEATHER_CITY_CACHE_FILE" ]; then
		cached=$(cut -d'@' -f1 "$TMUX_POWERLINE_SEG_WEATHER_CITY_CACHE_FILE" 2>/dev/null)
	fi

	if ! __city_cache_is_fresh; then
		__city_refresh_in_background
	fi

	if [ -n "$cached" ]; then
		echo "📍 ${cached}"
	fi
	return 0
}

# Returns 0 if the city cache is still fresh, 1 if stale or missing.
__city_cache_is_fresh() {
	[ -f "$TMUX_POWERLINE_SEG_WEATHER_CITY_CACHE_FILE" ] || return 1
	local last_update time_now
	last_update=$(cut -d'@' -f2 "$TMUX_POWERLINE_SEG_WEATHER_CITY_CACHE_FILE" 2>/dev/null)
	[ -n "$last_update" ] || return 1
	time_now=$(date +%s)
	[ "$((time_now - last_update))" -lt "$TMUX_POWERLINE_SEG_WEATHER_CITY_UPDATE_PERIOD" ]
}

# Spawn a detached process to refresh the city cache; no-op if one is running.
__city_refresh_in_background() {
	local lock_file="${TMUX_POWERLINE_DIR_TEMPORARY}/weather_city_refresh.lock"

	# Abandon a stale lock (older than the max plausible fetch time).
	if [ -f "$lock_file" ]; then
		local lock_mtime lock_age=0
		lock_mtime=$(stat -c "%Y" "$lock_file" 2>/dev/null || stat -f "%m" "$lock_file" 2>/dev/null)
		[ -n "$lock_mtime" ] && lock_age=$(($(date +%s) - lock_mtime))
		if [ "$lock_age" -le 30 ]; then
			return
		fi
		rm -f "$lock_file"
	fi

	# Acquire the lock atomically; bail out if another invocation beat us to it.
	if ! (set -o noclobber; : >"$lock_file") 2>/dev/null; then
		return
	fi

	(
		exec >/dev/null 2>&1
		trap 'rm -f "$lock_file"' EXIT
		command -v curl >/dev/null 2>&1 || exit 1
		command -v jq >/dev/null 2>&1 || exit 1

		local city="" data
		for api in "https://ipapi.co/json" "https://ipinfo.io/json"; do
			if data=$(curl --max-time 4 -s "$api"); then
				city=$(echo "$data" | jq -r '.city // empty')
				if [ -n "$city" ] && [ "$city" != "null" ]; then
					break
				fi
			fi
		done

		if [ -n "$city" ]; then
			printf '%s@%s\n' "$city" "$(date +%s)" >"$TMUX_POWERLINE_SEG_WEATHER_CITY_CACHE_FILE"
		fi
	) &
	disown
}
