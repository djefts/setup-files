# Dynamically update the terminal/tab title to "host@path"
update_terminal_title() {
  # Get shortened working directory (replace $HOME with ~)
  local cwd="${PWD/#$HOME/~}"
  local host_label

  # Detect execution environment
  if [[ -n "$SSH_CONNECTION" ]]; then
    host_label="$(hostname -s)" # Remote SSH host
  elif [[ -n "$WSL_INTEROP" ]]; then
    host_label="wsl2" # WSL 2 (has /run/WSL path)
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    host_label="wsl1" # WSL 1 fallback
  else
    host_label="localhost" # Native Linux or other
  fi

  # Set terminal/tab title to: host@path
  printf '\033]0;%s@%s\007' "$host_label" "$cwd"
}
