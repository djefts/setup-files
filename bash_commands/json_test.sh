# Send a test JSON request to an input endpoint
json_test() {
    if [[ $1 = "" ]]; then
        echo "Error- json_test command requires a target endpoint"
        return
    fi
    curl --header \"Content-Type: application/json\" --request POST --data '{\"hello\":\"world\"}' "$1"
}
