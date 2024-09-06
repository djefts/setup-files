# Docker command shortcuts
docker() {
    commands=("reset" "clean" "bash-test" "enter")
    if [[ $1 = "${commands[0]}" ]]; then
        # docker reset
        printf "Docker stopping everything...\n"
        # use `command` to prevent accidental recursion since we are overwriting the base `docker` command
        command docker ps -aq | xargs --no-run-if-empty "$(docker stop)"
        printf "\nDocker destroying everything...\n"
        command docker system prune --all --volumes --force
    elif [[ $1 = "${commands[1]}" && -n $2 ]]; then
        # docker clean
        printf "Docker stopping everything...\n"
        command docker ps -aq | xargs --no-run-if-empty "$(docker stop)"
        printf "\nDocker cleaning up build cache...\n"
        command docker builder prune --all --force
        printf "Docker cleaning up images...\n"
        command docker image prune --all --force
    elif [[ $1 = "${commands[2]}" ]]; then
        # docker bash-test
        command docker run --rm -it --entrypoint bash ubuntu
    elif [[ "$1" = "${commands[3]}" && -n $2 ]]; then
        # docker enter [container]
        command docker exec -it "$2" sh;
    elif [[ "$1" = "${commands[4]}" ]]; then
        # docker
        command docker
        printf "\nCustom Commands:\n"
        for c in "${commands[@]}"; do
            printf "    '%s'\n" "$c"
        done
    elif [[ -z $1 ]]; then
        # Base Docker output
        command docker;
        printf "\nCustom Docker Commands:\n";
        for c in "${commands[@]}"; do
            printf "\t'%s'\n" "$c"
        done;
    elif [[ ! " ${commands[*]} " =~ ^$1$ ]]; then
        # docker [actual command]
        command docker "$@"
    else
        printf "\nCUSTOM COMMANDS ERROR\n"
        printf "Command:\n--docker '%s'--\n" "$@"
    fi;
}
