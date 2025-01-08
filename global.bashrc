# shellcheck source=~

# DIRCOLORS Setup
eval "$(dircolors -b ~/setup-files/.dir_colors)"

echo "Setting up bash aliases..."
source ~/setup-files/.bash_aliases

# Make cd change terminal-path if following a symlink
alias cd="cd -P"

# Node.js Shell setup
echo "Setting up FNM Node environment..."
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  FNM_PATH="/mnt/c/Program Files FF/.fnm/"
elif [[ ' msys cygwin win32 ' =~ .*\ $OSTYPE\ .* ]]; then
  FNM_PATH=$(cygpath "/c/Program Files FF/.fnm/")
fi
if [ -d "$FNM_PATH" ]; then
  if [[ :$PATH: =~ (^|:)"$FNM_PATH"(:|$) ]]; then
    echo "fnm already on PATH"
  else
    export PATH="$FNM_PATH:$PATH"
  fi
  eval "$(fnm env --shell bash --fnm-dir "$FNM_PATH" --version-file-strategy recursive --corepack-enabled --resolve-engines)"
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    export PATH="$FNM_MULTISHELL_PATH:$PATH"
    export NODE_PATH="$FNM_MULTISHELL_PATH"
  elif [[ ' msys cygwin win32 ' =~ .*\ $OSTYPE\ .* ]]; then
    export PATH=$(cygpath "$FNM_MULTISHELL_PATH"):$PATH
    export NODE_PATH=$(cygpath "$FNM_MULTISHELL_PATH")
  fi
  fnm use
else
  echo "FNM not installed."
fi

echo "Setting up shared bash history..."
# Share Bash history between terminal windows
#   Courtesy of https://unix.stackexchange.com/a/1292
HISTCONTROL=ignoredups:erasedups # Avoid duplicates
# When the shell exits, append to the history file instead of overwriting it
shopt -s histappend
# After each command, append to the history file and reread it
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

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

echo "Setting up custom functions..."
# Source all of my custom commands files
for f in ~/setup-files/bash_commands/*; do source "$f"; done

echo "Setting up bash profile..."
# Force-Copy pre-built basic profile files to home directory
cp -a --remove-destination ~/setup-files/default_files/. -t ~/
# add global.gitconfig configurations without overwriting `git config --global`
# shellcheck disable=SC2088
command git config --global include.path "~/setup-files/global.gitconfig"

echo "hello_david"
