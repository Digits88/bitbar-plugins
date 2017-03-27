#!/usr/bin/env bash
export PATH="/usr/local/bin:/usr/bin:$PATH"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TW_AUTH=$(jq -r '.teamwork.auth' $DIR/config.json)

get_latest_clockin() {
    http GET digitalcrew.teamwork.com/me/clockins.json "Cookie:tw-auth=$TW_AUTH" | jq -r '.clockIns[0]'
}

update_clock() {
    http POST "digitalcrew.teamwork.com/me/clock$1.json" "Cookie:tw-auth=$TW_AUTH" > /dev/null
}

clock_in() {
    update_clock "in"
}

clock_out() {
    update_clock "out"
}

run() {
    local LATEST_CLOCKIN=$(get_latest_clockin)
    local CLOCKOUT_TIME=$(echo $LATEST_CLOCKIN | jq -r '.clockOutDatetime')
    local CLOCK_STATUS=$([[ -z "$CLOCKOUT_TIME" ]] && echo "in" || echo "out")
    local INVERTED_CLOCK_STATUS=$([[ ! -z "$CLOCKOUT_TIME" ]] && echo "in" || echo "out")

    echo "Clocked $CLOCK_STATUS"
    echo "---"
    echo "Clock $INVERTED_CLOCK_STATUS | bash=$DIR/time.5s.sh param1=clock_$INVERTED_CLOCK_STATUS terminal=false refresh=true"
}

"${@:-run}"