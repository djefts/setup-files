#set -e
#set -o pipefail

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Git shortcuts:
git() {
    # Customized Git commands:
    commands=('incoming', 'outgoing', 'modified', 'changed', 'tag', 'graph', 'search', 'pullall', '');

    alias branch='git branch --show-current';  # alias in subshell doesn't affect outside world
    if [[ $1 = $commands[0] ]]; then
        # Show incoming changes
        command git log ..origin/$(branch);
    elif [[ $1 = $commands[1] ]]; then
        # Show outgoing changes
        command git log origin/$(branch)..;
    elif [[ $1 = $commands[2] || $1 = $commands[3] ]]; then
        # Show diff with remote branch
	command git diff --name-status main;
    elif [[ $1 = $commands[4] && -z $2 ]]; then
        # Get tagging
        command git tag -n1;
    elif [[ $1 = $commands[5] ]]; then
        # Fancy commit graph
        command git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD
            %C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n'
            '%C(white)%s%C(reset) %C(dim white)- %an%C(reset)';
    elif [[ $1 = $commands[6] ]]; then
        # Search repo for term
        if [[ $2 = "" ]]; then
            echo "Error- custom search command requires a search term";
        else
            command git log -S$2 --all -p;
        fi
    elif [[ $1 = $commands[7] ]]; then
        # Safely pull all branches from all remotes
        REMOTES=$(git remote | xargs -n1 echo);
        CLB=$(git rev-parse --abbrev-ref HEAD);  # Current Local Branch
        echo "CLB: $CLB"
        echo "$REMOTES" | while read -r REMOTE; do
            git fetch --all;
            echo "updated $REMOTE";
            git remote show $REMOTE -n | awk '/merges with remote/{print $5" "$1}' | while read -r RB LB; do
                echo "checking branch $RB";
                # awk(search) for "[local-branch] merges with remote [remote-branch]" 
                ARB="refs/remotes/$REMOTE/$RB"; # remote branch full path name
                ALB="refs/heads/$LB"; # local branch full path name
                NBEHIND=$(( $(git rev-list --count $ALB..$ARB 2>NUL) + 0)); # unpushed local commits
                NAHEAD=$(( $(git rev-list --count $ARB..$ALB 2>NUL) + 0)); # unpulled remote commits
                if [ "$NBEHIND" -gt 0 ]; then
                    if [ "$NAHEAD" -gt 0 ]; then
                        echo " diverged branch $LB is $NBEHIND commit(s) behind and $NAHEAD commit(s) ahead of $REMOTE/$RB. could not be fast-forwarded";
                    elif [ "$LB" = "$CLB" ]; then
                        echo " current branch $LB was $NBEHIND commit(s) behind of $REMOTE/$RB. updating branch with fast-forward merge";
                        git pull --ff-only;
                    else
                        echo " non-current branch $LB was $NBEHIND commit(s) behind of $REMOTE/$RB. updating local branch to remote";
                        git fetch $REMOTE $ARB:$ALB; # fetch $ARB then fast-forward $ALB using $ARB
                    fi
                fi
            done
        done
    elif [[ $1 = $commands[8] ]]; then
        # git
        command git
        printf "\nCustom Commands:\n:"
        for c in ${commands[@]}; do
            printf "    '$c'\n"
        done
    else
        command git "$@"
    fi;
}

docker() {
    commands=("reset" "clean" "bash-test" "")
    if [[ $1 = ${commands[0]} ]]; then
        # docker reset
        printf "Docker stopping everything...\n"
        command docker ps -aq | xargs --no-run-if-empty docker stop
        printf "\nDocker destroying everything...\n"
        command docker system prune --all --volumes --force
    elif [[ $1 = ${commands[1]} && -z $2 ]]; then
        # docker clean
        printf "Docker stopping everything...\n"
        command docker ps -aq | xargs --no-run-if-empty docker stop
        printf "\nDocker cleaning up build cache...\n"
        command docker builder prune --all --force
        printf "Docker cleaning up images...\n"
        command docker image prune --all --force
    elif [[ $1 = ${commands[2]} ]]; then
        # docker bash-test
        command docker run --rm -it --entrypoint bash ubuntu
    elif [[ "$1" = ${commands[3]} ]]; then
        # docker
        command docker
        printf "\nCustom Commands:\n"
        for c in ${commands[@]}; do
            printf "    '$c'\n"
        done
    elif [[ ! " $commands[*]} " =~ "$1" ]]; then
        # docker [actual command]
        command docker "$@"
    else
        printf "\nCUSTOM COMMANDS ERROR\n"
        printf "Command:\n--docker '$@'--\n"
    fi;
}

# Copied from the default `aliases.sh` created by Git Bash:
# --show-control-chars: help showing Korean or accented characters
case "$TERM" in
xterm*)
	# The following programs are known to require a Win32 Console
	# for interactive usage, therefore let's launch them through winpty
	# when run inside `mintty`.
	for name in node ipython php php5 psql python2.7
	do
		case "$(type -p "$name".exe 2>/dev/null)" in
		''|/usr/bin/*) continue;;
		esac
		alias $name="winpty $name.exe"
	done
	;;
esac

# Print out my customizations
echo "$(alias)";
git;
docker;
