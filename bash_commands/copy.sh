# copy input into clipboard
copy() {
    windows_os=("msys" "win32" "cygwin")
    if [[ $OSTYPE =~ ^($(IFS=\| "${windows_os[*]}"))$ ]]; then
        clip
    else
        xclip -sel c < "$1"
    fi
}
