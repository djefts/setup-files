# Searching/highlighting
highlight() {
    # from https://askubuntu.com/a/1200851
    pattern=$1
    shift
    # shellcheck disable=SC2016
    sed '/'"${pattern}"'/,${s//\x1b[32m&\x1b[0m/g;b};$q5' "$@"
}
