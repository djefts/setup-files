printandexecute() {
    { printf Executing; printf ' %q' "$@"; echo; } >&2
    "$@"
}
alias() {
    for arg; do
        [[ "arg" == *=* ]] &&
        arg="${arg%%=*}=printandexecute ${arg#*=}"
        builtin alias "$arg"
    done
}

alias python3.12='/c/Users/djefts/AppData/Local/Programs/Python/Python312/python'
alias python3.11='/c/Users/djefts/AppData/Local/Programs/Python/Python311/python'
alias python3.10='/c/Users/djefts/AppData/Local/Programs/Python/Python310/python'
