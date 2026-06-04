# Git shortcuts:
git() { (
    set -e
    commands=("incoming" "outgoing" "modified" "changed" "tag" "graph" "search" "pullall")
    branch() {
        git branch --show-current
    }

    # all of these use `command` to prevent accidental recursion since 
    #   we are overwriting the base `git` command
    if [[ $1 = "${commands[0]}" ]]; then                                ### INCOMING
        # Show changes from origin to local
        command git fetch
        command git log ..origin/"$(branch)"
    elif [[ $1 = "${commands[1]}" ]]; then                              ### OUTGOING
        # Show changes to origin from local
        command git fetch
        command git log origin/"$(branch)"..
    elif [[ $1 = "${commands[2]}" || "$1" = "${commands[3]}" ]]; then   ### MODIFIED or CHANGED
        # Better git diff
        command git diff --name-status "$(branch)"
    elif [[ $1 = "${commands[4]}" && $2 = "" ]]; then                   ### TAG
        # Git tagging
        echo "Custom git tag command..."
        command git tag -n1
    elif [[ $1 = "${commands[5]}" && $2 = "" ]]; then                   ### GRAPH
        # Fancy Git graph output
        command git log --graph --pretty='%n' --date-order \
            --abbrev-commit --decorate --color=always \
            --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n%C(white)%s%C(reset) %C(dim white)- %an%C(reset)'
    elif [[ $1 = "${commands[6]}" ]]; then                              ### SEARCH
        # Search the repo
        if [[ $2 = "" ]]; then
            echo "Error- search command requires a search term"
        else
            command git log -S "$2" --all -p
        fi
    elif [[ $1 = "${commands[7]}" && $2 = "" ]]; then                   ### PULLALL
        # Pull all remote branches from origin that have a local copy
        CLB=$(git rev-parse --abbrev-ref HEAD) # Current Local Branch

        # Fetch all remotes with prune and tags (force overwrite local tags from server)
        git fetch --all --prune --tags --force || echo "some remotes had fetch errors (continuing anyway)"
        echo "fetched and pruned all remotes"

        # Delete local branches whose remote tracking branch is gone
        git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads | while read -r branch status; do
            if [[ "$status" == "[gone]" ]] && [[ "$branch" != "$CLB" ]]; then
                echo " deleting local branch $branch (remote was deleted)"
                git branch -D "$branch"
            fi
        done

        # Update all local branches that have upstream tracking
        git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads | while read -r LB upstream; do
            if [[ -n "$upstream" ]]; then
                echo "checking branch $LB (tracks $upstream)"
                ALB="refs/heads/$LB"                                       # local branch full path name
                ARB="refs/remotes/$upstream"                               # remote branch full path name
                NBEHIND=$(($(git rev-list --count "$ALB".."$ARB" 2> /dev/null) + 0)) # commits behind
                NAHEAD=$(($(git rev-list --count "$ARB".."$ALB" 2> /dev/null) + 0))  # commits ahead
                if [ "$NBEHIND" -gt 0 ]; then
                    if [ "$NAHEAD" -gt 0 ]; then
                        echo " diverged: $LB is $NBEHIND commit(s) behind and $NAHEAD commit(s) ahead of $upstream. could not be fast-forwarded"
                    elif [ "$LB" = "$CLB" ]; then
                        echo " updating current branch $LB ($NBEHIND commit(s) behind $upstream)"
                        git pull --ff-only
                    else
                        echo " updating branch $LB ($NBEHIND commit(s) behind $upstream)"
                        git fetch . "$ARB":"$ALB" # fast-forward local branch using remote ref
                    fi
                fi
            fi
        done
    elif [[ -z $1 ]]; then
        # Base Git output
        command git
        printf "\nCustom Git Commands:\n"
        for c in "${commands[@]}"; do
            printf "\t'%s'\n" "$c"
        done
    elif [[ ! "${commands[*]}" =~ ^$1$ ]]; then
        # git [actual command]
        command git "$@"
    else
        printf "\nCUSTOM COMMANDS ERROR\n"
        printf "Command:\n--git '%s'--\n" "$@"
    fi
); }
