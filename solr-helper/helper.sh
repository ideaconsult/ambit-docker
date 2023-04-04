#!/usr/bin/env bash
set -o nounset

msg() {
    echo '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'
    echo
    echo "$1"
    echo
    echo '* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *'
}

err() {
    msg "ERROR: $1" 1>&2
    exit 1
}

warn() {
    msg "WARNING: $1"
}

info() {
    msg "INFO: $1"
}

# Set up tools
[[ $EUID -eq 0 ]] && {
    # shellcheck disable=SC2015
    jq --help >/dev/null 2>&1 && unzip --help >/dev/null 2>&1 || {
        apt-get update
        apt-get install -y jq unzip
        rm -rf /var/lib/apt/lists/*
    }
exec setpriv --reuid "${SOLR_UID}" --regid "${SOLR_GID}" --init-groups "${0}"
}

# Source configuration
# shellcheck source=helper.conf
source "${0%.sh}.conf"

# Check required external variables
[[ -z ${AMBIT_SOLR_URL:-} || -z ${AMBIT_SOLR_USER:-} || -z ${AMBIT_SOLR_PASS:-} || -z ${ZK_HOST:-} ]] && {
    err 'AMBIT_SOLR_URL, AMBIT_SOLR_USER, AMBIT_SOLR_PASS, or ZK_HOST environment variable is not set.'
}

# Set up commands and variables
q="curl -s -u ${AMBIT_SOLR_USER}:${AMBIT_SOLR_PASS}"
s="${AMBIT_SOLR_URL%/}"

# Set up authentication
for (( i = "${tmout}"; i > 0; i-- )); do
    res="$( $q "${s}/api/cluster/security/authentication" | jq '."authentication.enabled"' 2>/dev/null)"
    [[ $res == 'false' || $res == 'null' ]] && {
        warn 'Ignore the instructions below to add SOLR_AUTH_TYPE and SOLR_AUTHENTICATION_OPTS to solr.in.sh.'
        solr auth enable -credentials "${AMBIT_SOLR_USER}:${AMBIT_SOLR_PASS}" -z "${ZK_HOST}" \
            || err 'Could not set up Solr authentication.'
        break
    }
    [[ $res == 'true' ]] && break
    sleep 1
done

# Upload configset
$q "${s}/api/cluster/configs" | jq -e ".configSets | index(\"${conf}\") >= 0" >/dev/null || {
    file="/opt/data_import/${conf}.zip"
    [[ -r ${file} ]] || {
        err "Zip archive of '${conf}' configuration missing from 'data_import' directory."
    }
    info "Uploading configset '${conf}'..."
    $q -X PUT -H 'Content-Type: application/octet-stream' --data-binary "@${file}" "${s}/api/cluster/configs/${conf}" \
        | jq -e '.responseHeader.status == 0' >/dev/null || err "Could not upload configset '${conf}'."
}

# Set up collection
$q "${s}/api/collections" | jq -e ".collections | index(\"${col}\") >= 0" >/dev/null || {
    post='{"create":{"name":"'"${col}"'","config":"'"${conf}"'","numShards":1,"replicationFactor":'"${repl}"'}}'
    info "Creating collection '${col}'..."
    $q -X POST -H 'Content-Type: application/json' --data "${post}" "${s}/api/collections" \
        | jq -e '.responseHeader.status == 0' >/dev/null || err "Could not set up collection '${col}'."
}

# Upload data
$q "${s}/api/cores" | jq -e '.status | length == 1' >/dev/null || {
    err 'Collection exists in Solr, but there are either no cores or more than one core. This is unexpected.'
}
$q "${s}/api/cores" | jq -e '.status[].index.numDocs > 0' >/dev/null || {
    for filename in "${data_files[@]}"; do
        [[ -r /opt/data_import/${filename} ]] || {
            err "Data file '${filename}' missing from 'data_import' directory."
        }
    done
    for filename in "${data_files[@]}"; do
        info "Uploading data from '${filename}'..."
        for datafile in $(unzip -l "/opt/data_import/${filename}" | awk '{ if (NR>3 && NF==4) print $4 }'); do
            info "Uploading '${datafile}'..."
            unzip -p "/opt/data_import/${filename}" "${datafile}" | \
                $q -X POST -H "Content-Type: application/json" -T - "${s}/${col}/update?commit=true" \
                    | jq -e '.responseHeader.status == 0' >/dev/null || err "Could not upload '${datafile}'."
        done
    done
}

info 'LRI Solr is initialized successfully.'
