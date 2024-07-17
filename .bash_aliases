aliases() {
    # Print out existing aliases
    for key in "${!BASH_ALIASES[@]}"; do
        printf '%s=%q\n' "$key" "${BASH_ALIASES[$key]}"
    done
}

# List Directory Fancy Stuff
alias ls='ls -aF --color=auto --show-control-chars'
alias ll='ls -lh'

# Python Version Bindings
alias python312='/c/Program Files FF/Python/Python312/python'
alias python311='/c/Program Files FF/Python/Python311/python'
alias python310='/c/Program Files FF/Python/Python310/python'
alias python38='/c/Program Files FF/Python/Python38/python'

# Git Shortcuts
alias gc='git commit'
alias gf='git fetch'
alias gs='git status'

# Miscellaneous
alias json-test="curl --header \"Content-Type: application/json\" --request POST --data '{\"hello\":\"world\"}'"
alias cd="cd -P"
