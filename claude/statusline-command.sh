#!/usr/bin/env bash

# Statusline Complete Rebuild - 2026-03-18
# Follows plan at ~/.claude/projects/-home-david-jefts/memory/statusline-rebuild-plan.md

#=== COLORS ===#
RESET="\033[0m"
BOLD="\033[1m"

## ANSI ##
# Standard colors
BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
GRAY="\033[37m"
# Bright Colors
BRIGHT_BLACK="\033[90m"
BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[12m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"
WHITE="\033[97m"
# Custom Colors
ORANGE="\033[38;5;202m"

# Box border color (sky blue, same as labels)
BOX_COLOR="\033[96m"

# Separator characters
BREAK=" ${BRIGHT_BLACK}|${RESET} "
SEPARATOR="${BRIGHT_BLACK}·${RESET}"

#=== CACHE SETUP ===#
CACHE_DIR="/tmp/claude-statusline-cache"
mkdir -p "$CACHE_DIR" 2>/dev/null
echo "" > "$CACHE_DIR/width-debug.log"

#=== COMMAND AVAILABILITY CHECKS (cache at startup) ===#
BC_AVAILABLE=false
if command -v bc >/dev/null 2>&1 && echo "1" | bc -l >/dev/null 2>&1; then
    BC_AVAILABLE=true
fi

PERL_AVAILABLE=false
if command -v perl >/dev/null 2>&1; then
    PERL_AVAILABLE=true
fi

DOCKER_AVAILABLE=false
if command -v docker >/dev/null 2>&1; then
    DOCKER_AVAILABLE=true
fi

SS_AVAILABLE=false
if command -v ss >/dev/null 2>&1; then
    SS_AVAILABLE=true
fi

#=== INPUT PARSING ===#
INPUT=$(cat)

#=== HELPER FUNCTIONS ===#

# 1. Simplify path: replace /home/david.jefts with ~, add trailing slash for dirs
simplify_path() {
    local path="$1"
    # Replace hardcoded home path
    path="${path/\/home\/david.jefts/\~}"
    # Add trailing slash if it's a directory and doesn't already have one
    if [[ -d "${path/#\~//home/david.jefts}" ]] && [[ ! "$path" =~ /$ ]]; then
        path="${path}/"
    fi
    echo "$path"
}

# 2. Format number with K/M/B/T suffix
format_number() {
    local num="$1"
    # Use awk for all float comparisons and formatting
    awk -v n="$num" 'BEGIN {
        if (n <= 1000) {
            printf "%.0f", n
        } else if (n <= 1000000) {
            printf "%.1fK", n / 1000
        } else if (n <= 1000000000) {
            printf "%.1fB", n / 1000000000
        } else if (n <= 1000000000000) {
            printf "%.1fT", n / 1000000000000
        } else {
            printf "DAMN FAM"
        }
    }'
}

# 3. Format time from milliseconds to "Xh Ym"
format_time() {
    local ms="$1"
    local seconds=$((ms / 1000))
    local minutes=$((seconds / 60))
    local hours=$((minutes / 60))
    local remaining_minutes=$((minutes % 60))
    echo "${hours}h ${remaining_minutes}m"
}

# 4. Format branch name: feature/SD-18232-desc -> feature::desc... (SD-18232)
format_branch() {
    local branch="$1"
    local max_desc_len=60

    # Check if it matches pattern: type/PROJECT-NUMBER-description
    if [[ "$branch" =~ ^([^/]+)/([A-Z]+-[0-9]+)-(.+)$ ]]; then
        local type="${BASH_REMATCH[1]}"
        local ticket="${BASH_REMATCH[2]}"
        local desc="${BASH_REMATCH[3]}"

        # Truncate description if too long
        if (( ${#desc} > max_desc_len )); then
            desc="${desc:0:max_desc_len}..."
        fi

        echo "${type}::${desc} (${ticket})"
    else
        echo "$branch"
    fi
}

# 5. Progress bar with colored bubbles
progress_bar() {
    local percentage="$1"

    # Color based on thresholds
    local color
    if (( $(bc -l <<< "${percentage}<33.3") )); then
        color="$GREEN"
    elif (( $(bc -l <<< "${percentage}<66.6") )); then
        color="$YELLOW"
    else
        color="$RED"
    fi

    local filled
    filled=$( bc -l <<< "scale=0;($percentage+5)/10" )
    local bar=""
    for ((i=0; i<10; i++)); do
        if ((i < filled)); then
            bar+="●"
        else
            bar+="○"
        fi
    done

    echo "${color}${bar}${RESET}"
}

# 6. Get visible length (accounting for ANSI codes and emoji width)
get_visible_length() {
    local text="$1"
    local debug="${2:-false}"

    # Strip ANSI codes
    local stripped
    # shellcheck disable=SC2001 # need regex not glob
    stripped=$(sed 's/\\033\[[0-9;]*m//g' <<< "${text}")

    # Count characters (Unicode-aware)
    # Strip variation selectors (U+FE0F) before counting since they have 0 display width
    # but bash/wc count them as characters
    local stripped_no_vs
    if [[ "$PERL_AVAILABLE" == "true" ]]; then
        stripped_no_vs=$(perl -C -pe 's/\x{FE0F}//g' <<< "$stripped")
    else
        stripped_no_vs="$stripped"
    fi
    local char_count=${#stripped_no_vs}

    # Count wide emojis (2-width) - these render as 2 chars wide but count as 1 character
    # Wide emojis: 📁🌿🧠💰🤖🧩🎫🐳💻🗜️🛑🚀📈📉⬇️🐌🚨🎯🔌🎨↗️↘️
    # Note: middle dot · and arrow → are 1-width
    # Use perl for better Unicode handling with alternation (not character class)
    local wide_count=0
    if [[ "$PERL_AVAILABLE" == "true" ]]; then
        # Include specific 2-width arrows: ↗️ (U+2197), ↘️ (U+2198) but NOT → (U+2192)
        wide_count=$(perl -C -ne 'print "$&\n" while /([\x{1F300}-\x{1F9FF}\x{2197}\x{2198}\x{2B00}-\x{2BFF}]\x{FE0F}?)/g' <<< "$stripped" | wc -l)
    else
        wide_count=$(grep -oE '(📁|🌿|🧠|💰|🤖|🧩|🎫|🐳|💻|🖥️|💾|🛑|🚀|📈|📉|⬇️|🐌|🚨|🎯|🔌|🎨|↗️|↘️)' <<< "$stripped" | wc -l)
    fi

    # Debug output if requested
    if [[ "$debug" == "true" ]]; then
        echo "DEBUG: stripped='$stripped'" >> "$CACHE_DIR/width-debug.log"
        echo "DEBUG: char_count=$char_count wide_count=$wide_count total=$((char_count + wide_count))" >> "$CACHE_DIR/width-debug.log"
        # Show which emojis were found
        if [[ "$PERL_AVAILABLE" == "true" ]]; then
            local found_emojis=$(perl -C -ne 'print "$&\n" while /([\x{1F300}-\x{1F9FF}\x{2197}\x{2198}\x{2B00}-\x{2BFF}]\x{FE0F}?)/g' <<< "$stripped" | tr '\n' ' ')
            echo "DEBUG: found_emojis='$found_emojis'" >> "$CACHE_DIR/width-debug.log"
        fi
    fi

    # Display width = character count + extra width from 2-width emojis
    echo $((char_count + wide_count))
}

# 7. Get Jira sprint data via MCP
get_jira_sprint_data() {
    local cache_file="$CACHE_DIR/jira-sprint.cache"
    local cache_ttl=300  # 5 minutes

    # Check cache exists
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
        # Check cache is fresh
#        if (( cache_age < cache_ttl )); then
#            # cache fresh, no need to reload
#            return 0
#        fi
    fi

    # Read MCP config
    local mcp_config="/home/david.jefts/.claude.json"
    if [[ ! -f "$mcp_config" ]]; then
        echo "MCP config not found"
        return 1
    fi
    IFS=$'\t' read -r mcp_url jira_token conf_token < <(jq -r '.mcpServers."river-mcp" | "\(.url)\t\(.headers.JiraToken)\t\(.headers.ConfluenceToken)"' "$mcp_config" 2>/dev/null)
    if [[ -z "$mcp_url" || "$mcp_url" == "null" || -z "$jira_token" || "$jira_token" == "null" || -z "$conf_token" || "$conf_token" == "null" ]]; then
        echo "Jira MCP server not configured"
        return 1
    fi

    # Query Jira via MCP
    local jql="assignee = currentUser() AND sprint in openSprints()"
    local fields="status,customfield_10106,customfield_10104,priority,updated"
    local response=$(curl -s -X POST "$mcp_url" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -H "JiraToken: $jira_token" \
        -H "ConfluenceToken: $conf_token" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"jira_search\",\"arguments\":{\"jql\":\"$jql\",\"fields\":\"$fields\",\"limit\":50}},\"id\":1}" \
        2>/dev/null)
    local jira_json=$(grep "^data: " <<< "$response" | sed 's/^data: //' | jq -r '.result.content[0].text' 2>/dev/null)
    jq '.issues[0]' <<< "$jira_json" > "$CACHE_DIR/first-issue.json"
    if [[ -z "$jira_json" ]] || [[ "$jira_json" == "null" ]]; then
        echo "Failed to fetch sprint data"
        return 1
    fi

    # Parse
    local todo=0 in_progress=0 in_review=0 complete=0 blocked=0
    local total_pts=0 done_pts=0
    local sprint_start="" sprint_end=""

    # Count tickets by status
    while IFS= read -r issue; do
        IFS=$'\t' read -r status status_cat story_pts < <(jq -r '[.status.name // "Unknown", .status.category // "Unknown", .customfield_10106.value // 0] | @tsv' <<< "${issue}" 2>/dev/null)
        story_pts=${story_pts%.*}  # ignore decimals
        # Get sprint dates from first issue
        if [[ -z "$sprint_start" ]]; then
            local sprint_data=$(echo "$issue" | jq -r '.customfield_10104.value[0] // ""' 2>/dev/null)
            if [[ -n "$sprint_data" && "$sprint_data" != "null" ]]; then
                # Extract dates from Java toString format: startDate=2026-03-17T13:55:00.000Z
                sprint_start=$(echo "$sprint_data" | grep -oP 'startDate=\K[^,\]]+' | head -1)
                sprint_end=$(echo "$sprint_data" | grep -oP 'endDate=\K[^,\]]+' | head -1)
            fi
        fi
        # Add to total points (use awk for floating point addition)
        if [[ "$story_pts" != "null" ]] && [[ "$story_pts" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            total_pts=$((total_pts + story_pts))
        fi
        # Categorize
        if [[ "$status" == "Blocked" ]]; then
            blocked=$((blocked+1))
        elif [[ "$status_cat" == "Done" ]] || [[ "$status" =~ ^(Done|Closed|Resolved)$ ]]; then
            complete=$((complete+1))
            done_pts=$((done_pts + story_pts))
        elif [[ "$status" =~ ^(In Review)$ ]]; then
            in_review=$((in_review+1))
        elif [[ "$status" =~ ^(In Work|In Progress)$ ]]; then
            in_progress=$((in_progress+1))
        else
            todo=$((todo + 1))
        fi
    done < <(jq -c '.issues[]' <<< "$jira_json" 2>/dev/null)

    # Write cache
    echo "${todo},${in_progress},${in_review},${complete},${blocked},${done_pts},${total_pts},${sprint_start},${sprint_end}" > "$cache_file"
}

# 8. Box drawing functions
draw_top_border() {
    local width="$1"
    local border=$(printf '═%.0s' $(seq 1 $((width-2))))
    echo -e "${BOX_COLOR}╔${border}╗${RESET}"
}

draw_bottom_border() {
    local width="$1"
    local border=$(printf '═%.0s' $(seq 1 $((width-2))))
    echo -e "${BOX_COLOR}╚${border}╝${RESET}"
}

draw_separator() {
    local width="$1"
    local border=$(printf '═%.0s' $(seq 1 $((width-2))))
    echo -e "${BOX_COLOR}╠${border}╣${RESET}"
}

draw_content_line() {
    local text="$1"
    local width="$2"
    local visible_len=$(get_visible_length "$text")
    local padding=$((width - visible_len - 4 + 1))  # 4 = "║ " + " ║"

    local spaces=$(printf ' %.0s' $(seq 1 $padding))

    echo -e "${BOX_COLOR}║${RESET} ${text}${spaces}${BOX_COLOR}║${RESET}"
}

#=== DATA COLLECTION ===#
# Update cache in background (if necessary)
get_jira_sprint_data &

# Extract from JSON input - OPTIMIZED: Single jq call with tab-separated `output`
read -r SESSION_ID CWD PROJECT_DIR LINES_ADDED LINES_REMOVED CONTEXT_PCT \
    CONTEXT_CURRENT_INPUT CONTEXT_CURRENT_OUTPUT CONTEXT_CURRENT_CACHE_CREATE CONTEXT_CURRENT_CACHE_READ \
    TOTAL_INPUT_TOKENS TOTAL_OUTPUT_TOKENS TOTAL_COST TOTAL_DURATION_MS MODEL_NAME CC_VERSION \
    <<< "$(echo "$INPUT" | jq -r '[
        .session_id,
        .workspace.current_dir,
        .workspace.project_dir,
        .cost.total_lines_added,
        .cost.total_lines_removed,
        .context_window.used_percentage,
        .context_window.current_usage.input_tokens,
        .context_window.current_usage.output_tokens,
        .context_window.current_usage.cache_creation_input_tokens,
        .context_window.current_usage.cache_read_input_tokens,
        .context_window.total_input_tokens,
        .context_window.total_output_tokens,
        .cost.total_cost_usd,
        .cost.total_duration_ms,
        .model.display_name,
        .version
    ] | @tsv')"

# Apply defaults and formatting
[[ -z "$SESSION_ID" ]] && SESSION_ID=""
[[ -z "$CWD" ]] && CWD=$(pwd)
[[ -z "$LINES_ADDED" ]] && LINES_ADDED=0
[[ -z "$LINES_REMOVED" ]] && LINES_REMOVED=0
[[ -z "$CONTEXT_CURRENT_INPUT" ]] && CONTEXT_CURRENT_INPUT=0
[[ -z "$CONTEXT_CURRENT_OUTPUT" ]] && CONTEXT_CURRENT_OUTPUT=0
[[ -z "$CONTEXT_CURRENT_CACHE_CREATE" ]] && CONTEXT_CURRENT_CACHE_CREATE=0
[[ -z "$CONTEXT_CURRENT_CACHE_READ" ]] && CONTEXT_CURRENT_CACHE_READ=0
[[ -z "$TOTAL_INPUT_TOKENS" ]] && TOTAL_INPUT_TOKENS=0
[[ -z "$TOTAL_OUTPUT_TOKENS" ]] && TOTAL_OUTPUT_TOKENS=0
[[ -z "$TOTAL_COST" ]] && TOTAL_COST=0
[[ -z "$TOTAL_DURATION_MS" ]] && TOTAL_DURATION_MS=0
[[ -z "$MODEL_NAME" ]] && MODEL_NAME=""
[[ -z "$CC_VERSION" ]] && CC_VERSION=""

TOTAL_TOKENS=$((TOTAL_INPUT_TOKENS + TOTAL_OUTPUT_TOKENS))

# Git
IS_GIT_REPO=false
BRANCH=""
STAGED=0
MODIFIED=0
UNTRACKED=0
AHEAD=0
BEHIND=0

if git rev-parse --git-dir >/dev/null 2>&1; then
    IS_GIT_REPO=true
    BRANCH=$(git --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

    STAGED=$(git --no-optional-locks diff --numstat --cached 2>/dev/null | wc -l)
    MODIFIED=$(git --no-optional-locks diff --numstat 2>/dev/null | wc -l)
    UNTRACKED=$(git --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l)

    # Dev divergence - combine ahead/behind in single rev-list call
    if [[ "$BRANCH" != "dev" ]] && [[ -n "$BRANCH" ]] && git rev-parse origin/dev >/dev/null 2>&1; then
        read -r AHEAD BEHIND < <(git --no-optional-locks rev-list --left-right --count origin/dev...HEAD 2>/dev/null | awk '{print $2, $1}')
    fi
fi


# Claude Code Configuration
# Debug: Save input to check field names (temporary for diagnostics)
echo "$INPUT" > "$CACHE_DIR/last-input.json"
# Check for thinking mode - try multiple field names
# Most likely: extendedThinking (standard field name in Claude Code)
THINKING_ENABLED=$(echo "$INPUT" | jq -r 'if .extendedThinking != null then .extendedThinking elif .thinkingEnabled != null then .thinkingEnabled elif .alwaysThinkingEnabled != null then .alwaysThinkingEnabled elif .thinking != null then .thinking else empty end')
# Debug log all possible thinking fields
echo "$INPUT" | jq -r '{extendedThinking, thinkingEnabled, alwaysThinkingEnabled, thinking}' > "$CACHE_DIR/thinking-fields.json" 2>/dev/null
OUTPUT_STYLE=$(echo "$INPUT" | jq -r '.output_style.name // empty')
[[ -z "$OUTPUT_STYLE" ]] && OUTPUT_STYLE="${RED}N/A${RESET}"
# Get reasoning effort and thinking mode from settings file if not in JSON input
REASONING_EFFORT=$(jq -r '.effortLevel // empty' "/home/david.jefts/.claude/settings.json" 2>/dev/null)
[[ -z "$REASONING_EFFORT" ]] && REASONING_EFFORT="${RED}N/A${RESET}"
THINKING_FROM_SETTINGS=$(jq -r '.extendedThinking // .thinking // empty' "/home/david.jefts/.claude/settings.json" 2>/dev/null)
# If thinking mode wasn't found in JSON input, try settings file
if [[ -z "$THINKING_ENABLED" ]] || [[ "$THINKING_ENABLED" == "false" ]]; then
    if [[ -n "$THINKING_FROM_SETTINGS" ]] && [[ "$THINKING_FROM_SETTINGS" != "false" ]]; then
        THINKING_ENABLED="$THINKING_FROM_SETTINGS"
    fi
fi
# Default to N/A if still not found
[[ -z "$THINKING_ENABLED" ]] && THINKING_ENABLED="N/A"


# Jira Data from cache
IFS=',' read -r TICKETS_TODO TICKETS_INPROGRESS TICKETS_INREVIEW TICKETS_COMPLETE TICKETS_BLOCKED \
    POINTS_DONE POINTS_TOTAL SPRINT_START SPRINT_END < "${CACHE_DIR}/jira-sprint.cache"
# convert to ints for math
POINTS_DONE=${POINTS_DONE%.*}
POINTS_TOTAL=${POINTS_TOTAL%.*}
echo "TICKET DEBUG: [${TICKETS_TOTAL}, ${POINTS_DONE}/${POINTS_TOTAL}]" >> "$CACHE_DIR/width-debug.log"
# calc time
if [[ -n "${SPRINT_START}" ]] && [[ -n "${SPRINT_END}" ]]; then
    TICKETS_TOTAL=$(( TICKETS_TODO + TICKETS_INPROGRESS + TICKETS_INREVIEW + TICKETS_COMPLETE + TICKETS_BLOCKED ))
    SPRINT_START=$(date -d "${SPRINT_START}" +%s 2>/dev/null || echo 0)
    SPRINT_END=$(date -d "${SPRINT_END}" +%s 2>/dev/null || echo 0)
    TIME_NOW=$(date +%s)

    if (( SPRINT_START > 0 && SPRINT_END > 0 )); then
        SPRINT_LENGTH=$(( (SPRINT_END - SPRINT_START) / 86400 ))
        DAYS_DONE=$(( (TIME_NOW - SPRINT_START) / 86400 ))
        DAYS_LEFT=$(( (SPRINT_END - TIME_NOW) / 86400 ))
        if (( SPRINT_LENGTH > 0 && DAYS_DONE > 0 && POINTS_TOTAL > 0 )); then
            EXPECTED_PACE=$(bc -l <<< "${POINTS_TOTAL} / ${SPRINT_LENGTH}")
            POINTS_TARGET=$(bc -l <<< "${EXPECTED_PACE} * ${DAYS_DONE}")
            DAYS_OFF=$(bc -l <<< "scale=1;(${POINTS_DONE} - ${POINTS_TARGET}) / ${EXPECTED_PACE}")
        fi
        if (( TICKETS_TOTAL > 0 )); then
            SPRINT_TICKET_AVG=$(bc -l <<< "${SPRINT_LENGTH} / ${TICKETS_TOTAL}")
        fi
    fi
fi
echo "SPRINT DEBUG: [${SPRINT_START}->${SPRINT_END}, ${DAYS_DONE}/${SPRINT_LENGTH}]" >> "$CACHE_DIR/width-debug.log"
echo "CALCS DEBUG: [${EXPECTED_PACE}, ${POINTS_TARGET}, ${DAYS_OFF}, ${SPRINT_TICKET_AVG}]" >> "$CACHE_DIR/width-debug.log"


# Services (use cached command availability)
if [[ "$DOCKER_AVAILABLE" == "true" ]]; then
    DOCKER_COUNT=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
    [[ -z "$DOCKER_COUNT" ]] && DOCKER_COUNT="${RED}N/A${RESET}"
else
    DOCKER_COUNT="${RED}N/A${RESET}"
fi

if [[ "$SS_AVAILABLE" == "true" ]]; then
    PORT_COUNT=$(ss -ltn 2>/dev/null | grep -E ':(3000|8080|5000|4200|8000|9000|3001|5173|4000)' | wc -l)
    [[ -z "$PORT_COUNT" ]] && PORT_COUNT="${RED}N/A${RESET}"
else
    PORT_COUNT="${RED}N/A${RESET}"
fi


# System metrics
if [[ -f /proc/stat ]]; then
    read -r idle1 total1 < <(awk '/^cpu /{print $5+$6,$2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat)
    sleep 0.1
    read -r idle2 total2 < <(awk '/^cpu /{print $5+$6,$2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat)

    if (( total1 > 0 && total2 > 0 )); then
        CPU_PCT=$(bc -l <<< "scale=1;($total2-$total1-$idle2+$idle1)*100/($total2-$total1)")
        CPU_BAR=$(progress_bar "$CPU_PCT")
        CPU_DISPLAY="${CPU_PCT}% $CPU_BAR"
    else
        CPU_DISPLAY="${RED}N/A${RESET}"
    fi
else
    CPU_DISPLAY="${RED}N/A${RESET}"
fi
MEM_PCT=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%.1f",(t-a)/t*100}' /proc/meminfo)
if [[ -z "$MEM_PCT" ]]; then
    MEM_DISPLAY="${RED}N/A${RESET}"
else
    MEM_BAR=$(progress_bar "$MEM_PCT")
    MEM_DISPLAY="${MEM_PCT}% $MEM_BAR"
fi
DISK_PCT=$(df "$PWD" 2>/dev/null | awk 'NR==2 {print int($5)}')
if [[ -z "$DISK_PCT" ]]; then
    DISK_DISPLAY="${RED}N/A${RESET}"
else
    DISK_BAR=$(progress_bar "$DISK_PCT")
    DISK_DISPLAY="${DISK_PCT}% $DISK_BAR"
fi


###=== LINE CONSTRUCTION ===###

# Line 1: Directory
CWD_SIMPLE=$(simplify_path "$CWD")
LINE1="📁 ${CYAN}${BOLD}CWD:${RESET} ${CYAN}${CWD_SIMPLE}${RESET}"
if [[ -n "$PROJECT_DIR" ]] && [[ "$PROJECT_DIR" != "$CWD" ]]; then
    PROJ_SIMPLE=$(simplify_path "$PROJECT_DIR")
    LINE1+=" ${BREAK} ${CYAN}${BOLD}Proj:${RESET} ${YELLOW}${PROJ_SIMPLE}${RESET}"
fi

# Line 2: Git
if [[ "$IS_GIT_REPO" == "true" ]]; then
    if [[ -z "$BRANCH" ]]; then
        BRANCH_DISPLAY="${RED}N/A${RESET}"
    else
        BRANCH_DISPLAY=$(format_branch "$BRANCH")
    fi

    GIT_INFO="${BOLD}${MAGENTA}${BRANCH_DISPLAY}${RESET} ${GREEN}s:${STAGED}${RESET} ${YELLOW}m:${MODIFIED}${RESET}"

    if (( UNTRACKED > 0 )); then
        GIT_INFO+=" ${RED}u:${UNTRACKED}${RESET}"
    fi

    # Dev divergence display
    if (( AHEAD > 0 && BEHIND > 0 )); then
        GIT_INFO+="${BREAK}${CYAN}origin/dev ↗️${AHEAD} ↘️${BEHIND}${RESET}"
    elif (( AHEAD > 0 )); then
        GIT_INFO+="${BREAK}${CYAN}origin/dev ↗️${AHEAD}${RESET}"
    elif (( BEHIND > 0 )); then
        GIT_INFO+="${BREAK}${CYAN}origin/dev ↘️${BEHIND}${RESET}"
    fi

    LINE2="🌿 ${GIT_INFO}"
else
    LINE2="🌿 ${GRAY}Not a git repository${RESET}"
fi

# Line 3: Context
if [[ -n "$CONTEXT_PCT" ]]; then
    CONTEXT_BAR=$(progress_bar "$CONTEXT_PCT")
    CONTEXT_COLOR="${GREEN}"
    if (( $(awk "BEGIN {print ($CONTEXT_PCT >= 75)}") )); then
        CONTEXT_COLOR="${RED}"
    elif (( $(awk "BEGIN {print ($CONTEXT_PCT >= 50)}") )); then
        CONTEXT_COLOR="${YELLOW}"
    fi

    # Calculate current turn total using correct formula:
    # I/O = input_tokens + output_tokens
    # Cache = cache_creation_input_tokens + cache_read_input_tokens
    # Total = I/O + Cache
    CONTEXT_CURRENT_IO=$((CONTEXT_CURRENT_INPUT + CONTEXT_CURRENT_OUTPUT))
    CONTEXT_CURRENT_CACHE=$((CONTEXT_CURRENT_CACHE_CREATE + CONTEXT_CURRENT_CACHE_READ))
    CONTEXT_CURRENT_TOTAL=$((CONTEXT_CURRENT_IO + CONTEXT_CURRENT_CACHE))

    # Display as equation: I/O + Cache = Total
    LINE3="🧠 ${CYAN}${BOLD}Context:${RESET} ${CONTEXT_BAR} ${CONTEXT_COLOR}${CONTEXT_PCT}%${RESET} 💾 ${GRAY}User: $(format_number $CONTEXT_CURRENT_IO) + Cache: $(format_number $CONTEXT_CURRENT_CACHE) = Total: $(format_number $CONTEXT_CURRENT_TOTAL)${RESET}"
else
    LINE3="🧠 ${CYAN}${BOLD}Context:${RESET} ${RED}N/A${RESET}"
fi

# Line 4: Session
LINE4="💸 ${CYAN}${BOLD}Session:${RESET} "
if [[ "$TOTAL_DURATION_MS" != "0" ]] && [[ -n "$TOTAL_DURATION_MS" ]]; then
    FORMATTED_TIME="${GRAY}$(format_time "$TOTAL_DURATION_MS")${RESET}"
    HOURS=$(bc -l <<< "scale=2;${TOTAL_DURATION_MS}/3600000")
    TOKEN_RATE=$(awk '{if ($2 > 0) printf "%.1f", $1 / $2; else print "0"}' <<< "$TOTAL_TOKENS $HOURS")

    if [[ "$TOTAL_COST" == "N/A" ]]; then
        COST_RATE="${RED}N/A${RESET}"
        COST_DISPLAY="${RED}N/A${RESET}"
    else
        COST_RATE="${GREEN}\$$(awk '{if ($2 > 0) printf "%.2f", $1 / $2; else print "0.00"}' <<< "$TOTAL_COST $HOURS")/hr${RESET}"
        COST_DISPLAY="${GREEN}\$$(awk '{printf "%.2f", $1}' <<< "${TOTAL_COST}")${RESET}"
    fi
    LINE4+="${GRAY}$(format_number $TOTAL_TOKENS) tok${RESET} ${SEPARATOR} ${COST_DISPLAY} ${SEPARATOR} ${FORMATTED_TIME} ${SEPARATOR} ${GREEN}+${LINES_ADDED}${RESET}${GRAY}/${RED}-${LINES_REMOVED}${RESET} ${GRAY}lines${RESET} ${BREAK} ${GRAY}$(format_number "${TOKEN_RATE}")/hr${RESET} ${SEPARATOR} ${COST_RATE}"
else
    LINE4+="${RED}N/A${RESET}"
fi

# Line 5: Model
LINE5="🤖 ${CYAN}${BOLD}Model:${RESET} ${WHITE}${MODEL_NAME}${RESET} ${GRAY}(${CC_VERSION})${RESET}"

# Line 6: Settings
if [[ "$THINKING_ENABLED" == "N/A" ]]; then
    THINKING_STATUS="${RED}N/A${RESET}"
elif [[ "$THINKING_ENABLED" == "true" ]]; then
    THINKING_STATUS="${GREEN}ON${RESET}"
else
    THINKING_STATUS="${YELLOW}OFF${RESET}"
fi
LINE6="🧩 ${CYAN}${BOLD}Thinking:${RESET} ${THINKING_STATUS} ${BREAK} ${CYAN}${BOLD}Reasoning:${RESET} ${YELLOW}${REASONING_EFFORT}${RESET} ${BREAK} 🎨 ${CYAN}${BOLD}Style:${RESET} ${YELLOW}${OUTPUT_STYLE}${RESET}"

# Line 7: Jira
# Determine status
if [[ -n "${DAYS_OFF}" ]]; then
    if (( $(bc -l <<< "${DAYS_OFF} >= 2") )); then
        burndown_emoji="🚀"
        burndown_msg="Usain Bolt"
        burndown_days="+${DAYS_OFF}d"
    elif (( $(bc -l <<< "${DAYS_OFF} >= 0.5") )); then
        burndown_emoji="📈"
        burndown_msg="You shmoovin!"
        burndown_days="+${DAYS_OFF}d"
    elif (( $(bc -l <<< "${DAYS_OFF} > -0.5") )); then
        burndown_emoji="🎯"
        burndown_msg="on track"
        burndown_days="${DAYS_OFF}d"
    elif (( $(bc -l <<< "${DAYS_OFF} > -${SPRINT_TICKET_AVG}") )); then
        burndown_emoji="📉"
        burndown_msg="Get faster"
        burndown_days="${DAYS_OFF}d"
    elif (( $(bc -l <<< "${DAYS_OFF} > -(${SPRINT_TICKET_AVG} * 2)") )); then
        burndown_emoji="⬇️"
        burndown_msg="You're behind!"
        burndown_days="${DAYS_OFF}d"
    elif (( $(bc -l <<< "${DAYS_OFF} > -(${SPRINT_TICKET_AVG} * 3)") )); then
        burndown_emoji="🐌"
        burndown_msg="WORK FASTER"
        burndown_days="${DAYS_OFF}d"
    elif (( $(bc -l <<< "${DAYS_OFF} < ${DAYS_LEFT}") )); then
        burndown_emoji="🚨"
        burndown_msg="SPRINT AT RISK"
        burndown_days="${DAYS_OFF}d"
    else
        burndown_emoji="☠️"
        burndown_msg="RIP"
        burndown_days="${DAYS_OFF}d"
    fi
else
    burndown_emoji=""
    burndown_msg="ERROR"
    burndown_days="ERROR"
fi
ticket_display="${GRAY}tickets: ${TICKETS_TODO} → ${TICKETS_INPROGRESS} → ${TICKETS_INREVIEW} → ${TICKETS_COMPLETE}${RESET} ${SEPARATOR} 🛑 ${GRAY}${TICKETS_BLOCKED}${RESET}"
burndown_display="${GRAY}${POINTS_DONE}/${POINTS_TOTAL}pts${RESET} ${SEPARATOR} ${GRAY}${burndown_days} left${RESET} ${SEPARATOR} ${GRAY}${burndown_emoji} ${burndown_msg}${RESET}"
LINE7="🎫 ${CYAN}${BOLD}Jira:${RESET} ${ticket_display} ${BREAK} ${burndown_display}"

# Line 8: Services
# Handle N/A values for docker and ports
if [[ "$DOCKER_COUNT" == "${RED}N/A${RESET}" ]]; then
    DOCKER_DISPLAY="${RED}N/A${RESET}"
else
    DOCKER_DISPLAY="${GREEN}${DOCKER_COUNT}${RESET} ${WHITE}containers${RESET}"
fi

if [[ "$PORT_COUNT" == "${RED}N/A${RESET}" ]]; then
    PORT_DISPLAY="${RED}N/A${RESET}"
else
    PORT_DISPLAY="${GREEN}${PORT_COUNT}${RESET} ${WHITE}ports active${RESET}"
fi

LINE8="🐳 ${CYAN}${BOLD}Services:${RESET} ${DOCKER_DISPLAY} ${BREAK} 🔌 ${PORT_DISPLAY}"

# Line 9: System
LINE9="🖥️ ${CYAN}${BOLD}CPU${RESET} ${CPU_DISPLAY} ${BREAK} ${CYAN}${BOLD}MEM${RESET} ${MEM_DISPLAY} ${BREAK} ${CYAN}${BOLD}DISK${RESET} ${DISK_DISPLAY}"

#=== BOX DRAWING ===#

# Calculate max width with debug
MAX_WIDTH=0
echo "=== DEBUG: Line Width Analysis ===" >> "$CACHE_DIR/width-debug.log"
line_num=1
for line in "$LINE1" "$LINE2" "$LINE3" "$LINE4" "$LINE5" "$LINE6" "$LINE7" "$LINE8" "$LINE9"; do
    echo "--- Line $line_num ---" >> "$CACHE_DIR/width-debug.log"
    len=$(get_visible_length "$line" "true")
    echo "DEBUG: calculated length=$len" >> "$CACHE_DIR/width-debug.log"
    if (( len > MAX_WIDTH )); then
        MAX_WIDTH=$len
    fi
    line_num=$((line_num + 1))
    echo "" >> "$CACHE_DIR/width-debug.log"
done
echo "DEBUG: MAX_WIDTH=$MAX_WIDTH" >> "$CACHE_DIR/width-debug.log"
echo "==================================" >> "$CACHE_DIR/width-debug.log"

# Add padding for borders
BOX_WIDTH=$((MAX_WIDTH + 4))

#=== OUTPUT ===#

draw_top_border "$BOX_WIDTH"
draw_content_line "$LINE1" "$BOX_WIDTH"
draw_content_line "$LINE2" "$BOX_WIDTH"
draw_content_line "$LINE3" "$BOX_WIDTH"
draw_content_line "$LINE4" "$BOX_WIDTH"
draw_separator "$BOX_WIDTH"
draw_content_line "$LINE5" "$BOX_WIDTH"
draw_content_line "$LINE6" "$BOX_WIDTH"
draw_content_line "$LINE7" "$BOX_WIDTH"
draw_content_line "$LINE8" "$BOX_WIDTH"
draw_content_line "$LINE9" "$BOX_WIDTH"
draw_bottom_border "$BOX_WIDTH"
