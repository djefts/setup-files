# import a standard KEY=value env file into the local environment
import() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "usage: import <env-file>" >&2
        return 2
    fi
    if [[ ! -f "$file" ]]; then
        echo "import: no such file: $file" >&2
        return 1
    fi

    # -a exports every variable the file assigns; . runs it as shell so
    # KEY=value, KEY='some value', comments and blanks all just work.
    set -a
    . "$file"
    set +a
}
