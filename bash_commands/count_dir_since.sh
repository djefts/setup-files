# Count the number of files in the input directory since an input time
count_dir() {
    if [[ $1 = "" || $2 = "" ]]; then
        echo "Error- count_dir command requires a target directory and time"
        return
    fi
    ls -lathr $(find "$1" -type f -newermt "$2") | tee >(ws -l);

}