# shellcheck source=~

# If not running interactively, don't do this stuff
case $- in
    *i*) ;;
    *) return;;
esac

echo "Welcome to your customized Bash profile!"

# Force-Copy pre-built basic profile files to home directory
cp -a --remove-destination ~/setup-files/default_files/. -t ~/
# add global.gitconfig configurations without overwriting `git config --global`
command git config --global include.path "~/setup-files/global.gitconfig"
# shellcheck disable=SC2088
command git config --global include.path "~/setup-files/global.gitconfig"

# DIRCOLORS Setup
eval "$(dircolors -b ~/setup-files/.dir_colors)"
case "$TERM" in xterm-color|*-256color)
    color_prompt=yes;;
esac
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
else
    color_prompt=
fi
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
#  SHARED BASH HISTORY
# ============================================================
echo "Setting up aliases and history..."
source ~/setup-files/.bash_aliases
# Make cd change terminal-path if following a symlink
alias cd="cd -P"
# Share Bash history between terminal windows
#   Courtesy of https://unix.stackexchange.com/a/1292
# Avoid duplicates and share history across sessions
HISTCONTROL=ignoredups:erasedups # Avoid duplicates
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
# check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Append and reread history on every prompt
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# Automatically hook into PROMPT_COMMAND if not already present
if [[ $PROMPT_COMMAND != *update_terminal_title* ]]; then
    if [[ -n "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="update_terminal_title; ${PROMPT_COMMAND}"
    else
        PROMPT_COMMAND="update_terminal_title"
    fi
fi


# ============================================================
#  WINPTY SETUP FOR GIT BASH
# ============================================================
# Copied from the default `aliases.sh` created by Git Bash:
case "$TERM" in
  xterm*)
    # The following programs are known to require a Win32 Console
    # for interactive usage, therefore let's launch them through winpty
    # when run inside `mintty`.
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
#  CUSTOM COMMANDS AND FUNCTIONS
# ============================================================
echo "Sourcing custom bash commands..."
for f in ~/setup-files/bash_commands/*; do
  source "$f"
done


# ============================================================
#  TERMINAL TITLE UPDATER
# ============================================================
# Ensure update_terminal_title is called each prompt if available
if declare -f update_terminal_title >/dev/null; then
  if [[ $PROMPT_COMMAND != *update_terminal_title* ]]; then
    echo "Terminal title updater..."
    if [[ -n "$PROMPT_COMMAND" ]]; then
      PROMPT_COMMAND="update_terminal_title; ${PROMPT_COMMAND}"
    else
      PROMPT_COMMAND="update_terminal_title"
    fi
  fi
fi

# Claude bug fix
export CLAUDE_CODE_ATTRIBUTION_HEADER=0

# enable programmable completion features
if ! shopt -oq posix; then
    echo "Setting up Bash completion..."
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

echo "hello_david"

