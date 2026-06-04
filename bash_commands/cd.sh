# Override cd to auto-list directory contents
cd() {
  builtin cd -P "$@" && ls
}
