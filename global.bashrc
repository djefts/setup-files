# shellcheck source=~

# DIRCOLORS Setup
eval "$(dircolors -b ~/setup-files/.dir_colors)"

if [ -f ~/setup-files/.bash_aliases ]; then
    . ~/setup-files/.bash_aliases
fi

# Make cd change terminal-path if following a symlink
alias cd="cd -P"

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
    for name in node ipython php php5 psql python2.7; do
        case "$(type -p "$name".exe 2> /dev/null)" in
            '' | /usr/bin/*)
                continue
                ;;
        esac
        alias $name="winpty $name.exe"
    done
    ;;
esac

# Source all of my custom commands files
for f in ~/setup-files/bash_commands/*; do source "$f"; done

# Force-Copy pre-built basic profile files to home directory
cp -af ~/setup-files/default_files/. -t ~/

echo "hello_david"
