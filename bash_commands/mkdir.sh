# mkdir + cd
mkdir() {
    command mkdir "$1" && cd "$1"
}
