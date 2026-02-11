# shellcheck source=~

# If not running interactively, don't do anything
case $- in
    *i*) ;;
    *) return;;
esac

echo "Setting up customized bash profile..."

# Force-Copy pre-built basic profile files to home directory
cp -a --remove-destination ~/setup-files/default_files/. -t ~/
# add global.gitconfig configurations without overwriting `git config --global`
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

# Bash Aliases
source ~/setup-files/.bash_aliases

# Make cd change terminal-path if following a symlink
alias cd="cd -P"

# Share Bash history between terminal windows
#   Courtesy of https://unix.stackexchange.com/a/1292
HISTCONTROL=ignoredups:erasedups # Avoid duplicates
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
# After each command, append to the history file and reread it
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

# Automatically hook into PROMPT_COMMAND if not already present
if [[ $PROMPT_COMMAND != *update_terminal_title* ]]; then
    if [[ -n "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="update_terminal_title; ${PROMPT_COMMAND}"
    else
        PROMPT_COMMAND="update_terminal_title"
    fi
fi

# check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Copied from the default `aliases.sh` created by Git Bash:
case "$TERM" in xterm*)
  # The following programs are known to require a Win32 Console
  # for interactive usage, therefore let's launch them through winpty
  # when run inside `mintty`.
  if [[ ' msys cygwin win32 ' =~ .\ $OSTYPE\ .* ]]; then
    for name in node ipython php php5 psql python2.7; do
      case "$(type -p "$name".exe 2>/dev/null)" in
        '' | /usr/bin/*)
          continue
          ;;
      esac
      alias $name="winpty $name.exe"
    done
  fi
  ;;
esac

# Source all of my custom commands files
for f in ~/setup-files/bash_commands/*; do source "$f"; done

# Claude Setup
#aws sso login --profile wsl
export CLAUDE_CODE_ATTRIBUTION_HEADER=0

# enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

cd ~/
echo "hello_david"
