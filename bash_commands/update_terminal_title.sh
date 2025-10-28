update_terminal_title() {
    local host_label
    local cwd="${PWD/#$HOME/~}"  # shorten home path to ~

    # Detect context
    if [[ -n "$SSH_CONNECTION" ]]; then
        host_label="$(hostname -s)"           # SSH session → remote hostname
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        host_label="wsl"                      # WSL environment
    else
        host_label="localhost"                # Regular local shell
    fi

    # Set tab/window title: host@path
    printf "\033]0;%s@%s\007" "$host_label" "$cwd"
}