# List Directory Fancy Stuff
# --show-control-chars: help showing Korean or accented characters
alias ls='ls -aF --color=auto --show-control-chars'
alias ll='ls -lathr'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Python Version Bindings
python_store="/c/Users/David\ Jefts/AppData/Local/Programs/Python"
if [[ $OSTYPE == "linux-gnu" ]]; then
  python_store="/mnt$python_store"
fi
alias python312="$python_store/Python312/python"
alias python311="$python_store/Python311/python"
alias python310="$python_store/Python310/python"
alias python38="$python_store/Python38/python"

# Git Shortcuts
alias gc='git commit'
alias gf='git fetch'
alias gs='git status --show-stash'

# Miscellaneous
alias cd="cd -P"
alias cdadvent="cd H:/Users/David\ Jefts/AdventOfCode"
alias authclaude="aws sso login --profile wsl"
