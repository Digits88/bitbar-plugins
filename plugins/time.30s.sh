#!/usr/bin/env bash
#
#   Teamwork Projects Clock Manager
#
#       Clock in and clock out from Teamwork project right from the taskbar.
#
#   Requirements:
#
#       A config.json in the parent directory (see config.example.json) and an tw-auth
#       cookie value for `teamwork.auth` property in the config file.
#
#   Dependencies:
#
#       jq      - brew install jq
#       curl    - brew install curl
#
export PATH="/usr/local/bin:/usr/bin:$PATH"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TW_AUTH=$(jq -r '.teamwork.auth' $DIR/../config.json)
PLUGIN_NAME=$(basename $0)
ISO_8601_DATE_FMT="%Y-%m-%dT%H:%M:%SZ"

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

pretty_timestamp() {
    local TIMESTAMP=$1
    local DATE=${TIMESTAMP:0:10}
    local TIME=${TIMESTAMP:11:8}
    local TODAY_DATE=$(date +"%Y-%m-%d")
    local YESTERDAY_DATE=$(date -v-1d +"%Y-%m-%d")

    echo -n "${TIME:0:5} " # Print the timestamp e.g. 12:55

    case $DATE in
        $TODAY_DATE)        echo "today" ;;
        $YESTERDAY_DATE)    echo "yesterday" ;;
        *)                  echo $DATE ;;
    esac
}

duration() {
    START=$(date -jf $ISO_8601_DATE_FMT $1 "+%s")
    END=$(date -jf $ISO_8601_DATE_FMT $2 "+%s")
    DURATION=$(($END - $START))
    HOURS=$(( $DURATION / 3600 ))
    MINUTES=$(( ($DURATION - ($HOURS * 3600)) / 60 ))

    echo "$HOURS hours and $MINUTES minutes"
}

capitalize() {
    echo $(tr '[:lower:]' '[:upper:]' <<< ${1:0:1})${1:1}
}

run() {
    local LATEST_CLOCKIN=$(get_latest_clockin)
    local USER_ID=$(echo $LATEST_CLOCKIN | jq -r '.userId')
    local CLOCKOUT_TIME=$(echo $LATEST_CLOCKIN | jq -r '.clockOutDatetime')
    local CLOCKIN_TIME=$(echo $LATEST_CLOCKIN | jq -r .clockInDatetime)
    local CLOCK_STATUS=$([[ -z "$CLOCKOUT_TIME" ]] && echo "in" || echo "out")
    local INVERTED_CLOCK_STATUS=$([[ ! -z "$CLOCKOUT_TIME" ]] && echo "in" || echo "out")

    echo ":clock1: $(capitalize $CLOCK_STATUS)"
    echo "---"

    if [[ "$CLOCK_STATUS" == "in" ]]; then
        echo "Clocked in since $(pretty_timestamp $CLOCKIN_TIME)."
    fi

    if [[ "$CLOCK_STATUS" == "out" ]]; then
        echo "Your last clock in was $(duration $CLOCKIN_TIME $CLOCKOUT_TIME)."
    fi

    echo "Clock $(capitalize $INVERTED_CLOCK_STATUS) | bash=\"$DIR/$PLUGIN_NAME\" param1=clock_$INVERTED_CLOCK_STATUS terminal=false refresh=true"
    echo "Open Time Manager | href=https://digitalcrew.teamwork.com/index.cfm#people/$USER_ID/time"
}

"${@:-run}"