# better ps | grep
ppgrep() {
    pgrep "$@" | xargs --no-run-if-empty ps -fp;
}
