# Git shortcuts:
git() {( set -e
    commands=("incoming" "outgoing" "modified" "changed" "tag" "graph" "search" "pullall");
    branch() {
        git branch --show-current
    }

    if [[ $1 = "${commands[0]}" ]]; then
        # Show changes from origin to local
        # use `command` to prevent accidental recursion since we are overwriting the base `docker` command
        command git fetch
        command git log ..origin/"$(branch)";
    elif [[ $1 = "${commands[1]}" ]]; then
        # Show changes to origin from local
        command git fetch
        command git log origin/"$(branch)"..;
    elif [[ $1 = "${commands[2]}" || "$1" = "${commands[3]}" ]]; then
        # Better git diff
	    command git diff --name-status "$(branch)";
    elif [[ $1 = "${commands[4]}" && -n $2 ]]; then
        # Git tagging
        command git tag -n1;
    elif [[ $1 = "${commands[5]}" ]]; then
        # Fancy Git graph output
        command git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n%C(white)%s%C(reset) %C(dim white)- %an%C(reset)';
    elif [[ $1 = "${commands[6]}" ]]; then
        # Search the repo
        if [[ $2 = "" ]]; then
            echo "Error- custom search command requires a search term";
        else
            command git log -S "$2" --all -p;
        fi
    elif [[ $1 = "${commands[7]}" ]]; then
        # Pull all remote branches from origin that have a local copy
        REMOTES=$(git remote | xargs -n1 echo)
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
                        git fetch "$REMOTE" "$ARB":"$ALB"; # fetch $ARB then fast-forward $ALB using $ARB
                    fi
                fi
            done
        done
    elif [[ -z $1 ]]; then
        # Base Git output
        command git;
        printf "\nCustom Git Commands:\n";
        for c in "${commands[@]}"; do
            printf "\t'%s'\n" "$c"
        done;
    elif [[ ! "${commands[*]}" =~ ^$1$ ]]; then
        # git [actual command]
        command git "$@"
    else
        printf "\nCUSTOM COMMANDS ERROR\n"
        printf "Command:\n--git '%s'--\n" "$@"
    fi;
)}
