# check if the current user is an administrator or not
isadmin() {
    if [[ $(sfc 2>&1|  tr -d "\0") =~ SCANNOW ]]; then
        echo "Yes:" Administrator;
    else
        echo "No: $USERNAME";
    fi
}
