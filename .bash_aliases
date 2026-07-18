# List Directory Fancy Stuff
# --show-control-chars: help showing Korean or accented characters
alias ls='ls -aF --color=auto --show-control-chars'
alias ll='ls -lathr'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Python stuff
python_store="/c/Users/David\ Jefts/AppData/Local/Programs/Python"
if [[ $OSTYPE == "linux-gnu" ]]; then
  python_store="/mnt$python_store"
fi
#alias python312="$python_store/Python312/python"
#alias python311="$python_store/Python311/python"
#alias python310="$python_store/Python310/python"
#alias python38="$python_store/Python38/python"
alias pyvenvin="source .venv/bin/activate"
alias pipcomp="pip-compile --no-header --strip-extras --annotate -rU"

# Git Shortcuts
alias gs='git status --show-stash'
alias vibes='git status --show-stash'
alias gc='git commit'
alias gf='git fetch'
alias yoink='git pullall'
alias kobe='git push'
alias yeet='git push --force-with-lease'
alias fukt='reset --hard HEAD'

# Miscellaneous
alias yarnfullinstall="yarn install --refresh-lockfile --check-cache --check-resolutions --inline-builds"
alias cdadvent="cd H:/Users/David\ Jefts/AdventOfCode"
alias authclaude="aws sso login --profile dev"
alias fuck_off='rm -rf'
alias reset='reset && . ~/.bashrc'
alias jitme='sudo epmcli --request-policies'

