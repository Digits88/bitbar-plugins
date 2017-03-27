#!/usr/bin/env bash
export PATH="/usr/local/bin:/usr/bin:$PATH"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TW_AUTH=$(jq -r '.teamwork.auth' $DIR/../config.json)
PLUGIN_NAME=$(basename $0)

get_latest_clockin() {
    curl -s -H "Cookie:tw-auth=$TW_AUTH" digitalcrew.teamwork.com/me/clockins.json | jq -r '.clockIns[0]'
}

update_clock() {
    curl -s -X POST -H "Cookie: tw-auth=$TW_AUTH" "digitalcrew.teamwork.com/me/clock$1.json"
}

clock_in() {
    update_clock in
}

clock_out() {
    update_clock out
}

run() {
    local LATEST_CLOCKIN=$(get_latest_clockin)
    local USER_ID=$(echo $LATEST_CLOCKIN | jq -r '.userId')
    local CLOCKOUT_TIME=$(echo $LATEST_CLOCKIN | jq -r '.clockOutDatetime')
    local CLOCK_STATUS=$([[ -z "$CLOCKOUT_TIME" ]] && echo "in" || echo "out")
    local INVERTED_CLOCK_STATUS=$([[ ! -z "$CLOCKOUT_TIME" ]] && echo "in" || echo "out")

    echo ":clock1: $CLOCK_STATUS"
    echo "---"
    echo "Clock $INVERTED_CLOCK_STATUS | bash=\"$DIR/$PLUGIN_NAME\" param1=clock_$INVERTED_CLOCK_STATUS terminal=false refresh=true"
    echo "Open Time Manager | href=https://digitalcrew.teamwork.com/index.cfm#people/$USER_ID/time"
}

"${@:-run}"