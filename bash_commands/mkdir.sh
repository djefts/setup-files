# mkdir + cd
mkdir() {
    command mkdir "$@" && cd "${@: -1}"
}
