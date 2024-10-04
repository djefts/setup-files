# Print a running count of the number of files in the input directory
count_dir() {
  if [[ $1 = "" ]]; then
    echo "Error- count_dir command requires a target directory"
    return
  fi
  while sleep 2; do
    echo -ne "\r$(find "$1" | wc -l)"
  done
}
