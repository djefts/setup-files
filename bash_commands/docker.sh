# Docker command shortcuts
docker() {
    commands=("reset" "clean" "bash-test" "enter" "ps")
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
        command docker exec -it "$2" sh
    elif [[ "$1" = "${commands[4]}" ]]; then
        # docker ps overwrite for cleaner output.
        # docker ps templates only expose the network NAME (e.g. glow_default),
        # not the host bridge INTERFACE (e.g. br-fireflydev) that firewall rules
        # target. Build a name->bridge map from `docker network inspect` and add
        # a BRIDGE column. Extra args after `ps` (e.g. -a) are passed through.
        shift
        {
            printf 'CONTAINER ID\tNAMES\tSTATUS\tPORTS\tNETWORKS\tBRIDGE\n'
            local _id _name _br _cid _names _status _ports _nets _out _n
            declare -A _bridge
            while IFS='|' read -r _id _name; do
                _br=$(command docker network inspect "$_id" \
                    --format '{{index .Options "com.docker.network.bridge.name"}}' 2>/dev/null)
                [[ -z $_br ]] && _br="br-${_id:0:12}"
                _bridge[$_name]=$_br
            done < <(command docker network ls --format '{{.ID}}|{{.Name}}')

            command docker ps "$@" \
                --format '{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Networks}}' \
            | while IFS=$'\t' read -r _cid _names _status _ports _nets; do
                _out=""
                local _arr; IFS=',' read -ra _arr <<< "$_nets"
                for _n in "${_arr[@]}"; do
                    _n="${_n# }"; _n="${_n% }"
                    _out="${_out:+$_out,}${_bridge[$_n]:-$_n}"
                done
                [[ -z $_ports ]] && _ports='-'
                [[ -z $_nets ]] && { _nets='-'; _out='-'; }
                printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
                    "$_cid" "$_names" "$_status" "$_ports" "$_nets" "$_out"
            done
        } | column -t -s $'\t'
    elif [[ "$1" = "${commands[5]}" ]]; then
        # docker
        command docker
        printf "\nCustom Commands:\n"
        for c in "${commands[@]}"; do
            printf "    '%s'\n" "$c"
        done
    elif [[ -z $1 ]]; then
        # Base Docker output
        command docker
        printf "\nCustom Docker Commands:\n"
        for c in "${commands[@]}"; do
            printf "\t'%s'\n" "$c"
        done
    elif [[ ! " ${commands[*]} " =~ ^$1$ ]]; then
        # docker [actual command]
        command docker "$@"
    else
        printf "\nCUSTOM COMMANDS ERROR\n"
        printf "Command:\n--docker '%s'--\n" "$@"
    fi
}
