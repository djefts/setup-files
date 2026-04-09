# shellcheck source=~

# ============================================================
#  INTERACTIVE CHECK
# ============================================================
# If not running interactively, don't do this stuff
case $- in
    *i*) ;;
    *) return;;
esac

echo "Welcome to your customized Bash profile!"


# ============================================================
#  CONFIG FILE SYNCHRONIZATION
# ============================================================
# Copy pre-built profile files from setup-files to home directory
echo "Copying default config files..."
cp -a --remove-destination ~/setup-files/default_files/. -t ~/

# Include global git config without overwriting local settings
echo "Configuring git..."
command git config --global include.path "~/setup-files/global.gitconfig"


# ============================================================
#  CUSTOM ALIASES AND COMMANDS
# ============================================================
# Load custom aliases and bash functions early so they're available everywhere
echo "Loading custom aliases and commands..."
source ~/setup-files/.bash_aliases
for f in ~/setup-files/bash_commands/*; do
  [[ "$(basename "$f")" == README* ]] && continue
  source "$f"
done


# ============================================================
#  COLORS AND PROMPT
# ============================================================
echo "Setting up colors..."
eval "$(dircolors -b ~/setup-files/.dir_colors)"

# Detect color support
case "$TERM" in xterm-color|*-256color)
    color_prompt=yes;;
esac
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_prompt=yes
else
    color_prompt=
fi

# Set prompt based on color support
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt


# ============================================================
#  NODE.JS SHELL SETUP (FNM/NVM)
# ============================================================
if [[ ' msys cygwin win32 ' =~ .*\ $OSTYPE\ .* ]]; then
  echo "Setting up FNM Node environment..."
  FNM_PATH=$(cygpath "/c/Program Files FF/.fnm/")

  if [[ -d "$FNM_PATH" ]]; then
    [[ :$PATH: != *":$FNM_PATH:"* ]] && export PATH="$FNM_PATH:$PATH"

    eval "$(fnm env --shell bash --fnm-dir "$FNM_PATH" \
      --version-file-strategy recursive \
      --corepack-enabled \
      --resolve-engines)"

    if [[ "$OSTYPE" == "linux-gnu" ]]; then
      export PATH="$FNM_MULTISHELL_PATH:$PATH"
      export NODE_PATH="$FNM_MULTISHELL_PATH"
    elif [[ ' msys cygwin win32 ' =~ .*\ $OSTYPE\ .* ]]; then
      export PATH="$(cygpath "$FNM_MULTISHELL_PATH"):$PATH"
      export NODE_PATH="$(cygpath "$FNM_MULTISHELL_PATH")"
    fi

    fnm use
  else
    echo "FNM not installed."
  fi
else
  echo "Setting up NVM environment..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi


# ============================================================
#  BASH HISTORY AND SHELL OPTIONS
# ============================================================
echo "Configuring history and shell options..."

# Make cd resolve symlinks (always use physical path)
alias cd="cd -P"

# Share Bash history between terminal windows
# Courtesy of https://unix.stackexchange.com/a/1292
HISTCONTROL=ignoredups:erasedups
shopt -s histappend
shopt -s checkwinsize
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"


# ============================================================
#  WINPTY SETUP (WINDOWS GIT BASH)
# ============================================================
# Launch certain programs through winpty for Windows compatibility
# Copied from default aliases.sh created by Git Bash
case "$TERM" in
  xterm*)
    if [[ ' msys cygwin win32 ' =~ .\ $OSTYPE\ .* ]]; then
      echo "Setting up WINPTY for Git Bash"
      for name in node ipython php php5 psql python2.7; do
        case "$(type -p "$name".exe 2>/dev/null)" in
          '' | /usr/bin/*) continue ;;
        esac
        alias $name="winpty $name.exe"
      done
    fi
    ;;
esac


# ============================================================
#  TERMINAL TITLE UPDATER
# ============================================================
# Hook update_terminal_title function into PROMPT_COMMAND if defined
if declare -f update_terminal_title >/dev/null; then
  if [[ $PROMPT_COMMAND != *update_terminal_title* ]]; then
    if [[ -n "$PROMPT_COMMAND" ]]; then
      PROMPT_COMMAND="update_terminal_title; ${PROMPT_COMMAND}"
    else
      PROMPT_COMMAND="update_terminal_title"
    fi
  fi
fi


# ============================================================
#  BASH COMPLETION
# ============================================================
# Enable programmable completion features
if ! shopt -oq posix; then
    echo "Setting up Bash completion..."
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi


# ============================================================
#  CRONTAB VALIDATION
# ============================================================
# Auto-install missing crontab entries from cron-scripts directory
# Only runs if crontab is available and user has permission
if command -v crontab &>/dev/null && crontab -l &>/dev/null; then
    echo "Checking crontab entries..."
    current_cron=$(crontab -l 2>/dev/null || echo "")
    new_entries=""
    while IFS= read -r script; do
        expected=$(grep "^# CRONTAB:" "$script" | sed 's/^# CRONTAB: //')
        if [[ -n "$expected" ]] && ! echo "$current_cron" | grep -qF "$(basename "$script")"; then
            echo "⚠️  Missing cron for $(basename "$script"), adding: $expected"
            new_entries="$new_entries$expected"$'\n'
        fi
    done < <(find ~/setup-files/cron-scripts -name "*.sh" -type f 2>/dev/null)
    if [[ -n "$new_entries" ]]; then
        (echo "$current_cron"; echo "$new_entries") | crontab -
    fi
fi


# ============================================================
#  ENVIRONMENT TWEAKS
# ============================================================
# Disable Claude Code attribution header
export CLAUDE_CODE_ATTRIBUTION_HEADER=0

printf "\nwelcome david\n"

