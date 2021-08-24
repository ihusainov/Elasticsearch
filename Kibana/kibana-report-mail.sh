#!/bin/bash
###########
# Author: Ildar Khusyainov
# 
# Description: This Script Create Report In Kibana Dashboard, then download csv and sent it via email
###########

# Default config

CURL="$(which curl)"
MUTT="$(which mutt)"
JQ="$(which jq)"
KIBANA_URL='https://elkusername:elkpassword@kibanaserver.local:5601'
GEN_REPORT_URL='/api/reporting/generate/csv?jobParams='
LOGFILE='/tmp/kibana_report.log'
CURL_OPTS=" -vvv --cacert /etc/elasticsearch/certs/ca.crt -XPOST -H 'kbn-xsrf: true' -H 'kbn-version: 7.10.0'"
START_DATE="$(date +%FT%TZ)"
END_DATE="$(date -d '-1 month' +%FT%TZ)"

QUERY=$(echo '(conflictedTypesFields:!(),fields:!(%27@timestamp%27,system.auth.hostname,system.auth.ssh.ip,system.auth.user,system.auth.ssh.method,system.auth.ssh.event,system.auth.ssh.geoip.country_name,system.auth.ssh.geoip.region_name),indexPatternId:%27cd95c1b0-0484-11eb-9763-f381e1305c38%27,metaFields:!(_source,_id,_type,_index,_score),searchRequest:(body:(_source:(excludes:!(),includes:!(%27@timestamp%27,system.auth.hostname,system.auth.ssh.ip,system.auth.user,system.auth.ssh.method,system.auth.ssh.event,system.auth.ssh.geoip.country_name,system.auth.ssh.geoip.region_name)),docvalue_fields:!(),query:(bool:(filter:!((bool:(minimum_should_match:1,should:!((exists:(field:system.auth.ssh.event)))))),must:!((range:(%27@timestamp%27:(format:strict_date_optional_time,gte:%27"$END_DATE"%27,lte:%27"$START_DATE"%27)))),must_not:!(),should:!())),script_fields:(),sort:!((%27@timestamp%27:(order:desc,unmapped_type:boolean))),stored_fields:!(%27@timestamp%27,system.auth.hostname,system.auth.ssh.ip,system.auth.user,system.auth.ssh.method,system.auth.ssh.event,system.auth.ssh.geoip.country_name,system.auth.ssh.geoip.region_name),version:!t),index:%27filebeat*%27),title:%27SSH%27,type:search)' | tr -d "\n")


FINAL_URL="${KIBANA_URL}${GEN_REPORT_URL}${QUERY}"

# Functions used else where in this script

log() {
        echo -e "`date` - $*"
        echo -e "`date` - $*" >> $LOGFILE
}
stop_on_error() {
        local RESULT=$?
        if [ "$RESULT" -ne "0" ]; then
                echo -e "[STOP ON ERROR]"
                exit $RESULT;
        fi
}

get_csv() {
        local STORE_PATH="/tmp"
        local FILENAME="kibana_report_$(date +%F_%H%M%S).csv"
        REPORT_NAME="$STORE_PATH/$FILENAME"
        log "Try to get csv link..."
                curl_exec="${CURL}  ${CURL_OPTS} \"${FINAL_URL}\""
                result="$(eval "${curl_exec}")"
                stop_on_error
        log "Get csv path..."
                path="$(echo "$result" | jq -c -r ".path")"
        log "$path"
        log "Download csv file to $REPORT_NAME"
                curl_exec="${CURL} --cacert /etc/elasticsearch/certs/ca.crt -XGET -H 'kbn-xsrf: true' -H 'kbn-version: 7.10.0'  \"${KIBANA_URL}${path}\""
                result="$(eval "${curl_exec}")"
                sleep 10        #Wait Report Creating
                while [[ $(grep -o 'processing' <<< $result) = 'processing' || $(grep -o 'pending' <<< $result) = 'pending' ]]
                do
                sleep 5
                curl_exec="${CURL} --cacert /etc/elasticsearch/certs/ca.crt  -XGET -H 'kbn-xsrf: true' -H 'kbn-version: 7.10.0'  \"${KIBANA_URL}${path}\""
                result="$(eval "${curl_exec}")"
                done
        echo "$result" > "$REPORT_NAME"
        log "Report was stored in $REPORT_NAME"
}

send_message() {
        local MESSAGE="Please, check logs"
        local SUBJECT="Kibana SSH Report"
        local MAILBOX="mailuser@contoso.com"

        log "Try to send email to ${MAILBOX}..."
        mutt_exec="${MUTT} -s \"${SUBJECT}\"  ${MAILBOX} -c mailrecipientcopy@contoso.com  -a \"${REPORT_NAME}\""
        result="$(eval "echo \"${MESSAGE}\" | ${mutt_exec}")"
        stop_on_error
        log "${result}"
}

# Clear log
> $LOGFILE

# Check for required config variables
if [ ! -x "${CURL}" ]; then
    echo "CURL is unset, empty, or does not point to curl executable. This script requires curl!" >&2
    exit 1
fi

get_csv
send_message
