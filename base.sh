#!/bin/bash

# set -x
set -eEuo pipefail

# Cleaning
_CLEAN_CMD=""

push_clean() {
    # set +x
    _CLEAN_CMD="$*"$'\n'"$_CLEAN_CMD"
    # set -x
    trap run_clean EXIT
}

run_clean() {
    set +eEuo pipefail
    log_info "Cleaning up"
    eval "$_CLEAN_CMD"
}
trap run_clean EXIT

## LOG
log_info() {
    >&2 echo -e "\033[34m[INF]\033[0m" "$@"
}
log_warn() {
    >&2 echo -e "\033[33m[WRN]\033[0m" "$@"
}
log_error() {
    >&2 echo -e "\033[31m[ERR]\033[0m" "$@"
}

## Helpers
# Returns a free port number starting form 3000
#
# Exits with code 1 if no port above 3000 is availible
function get_free_port() {
    netstat -aln | awk '
      $6 == "LISTEN" {
        if ($4 ~ "[.:][0-9]+$") {
          split($4, a, /[:.]/);
          port = a[length(a)];
          p[port] = 1
        }
      }
      END {
        for (i = 3000; i < 65000 && p[i]; i++){};
        if (i == 65000) {exit 1};
        print i
      }
    '
}

# Returns a random lowercase alphanumeric string of length 6
rand_str() {
    # Change pattern to `A-Za-z0-9` to get uppercase characters too.
    < /dev/urandom tr -dc 'a-z0-9' | head -c6 || true
}

pv() {
    sep=""
    for var in "$@"; do
        echo -n "$sep\e[2m$var=\e[0m'\e[1m${!var}\e[0m'"
        sep=" "
    done
}

run() {
    echo -e "\e[34m$: \e[2m$@\e[0m" >&2
    ${dry:-false} || eval "$@"
}

push_run() {
    echo -e "\e[34m$: \e[2m$@\e[0m" >&2
    ${dry:-false} || ( eval "$@" )
}

## ARG processing
req() {
    env="${1:-}"
    # fun="${2:-}"
    # shift 2
    # vals="$@"

    if [[ -z "${!env-}" ]]; then
        >&2 echo "Err: ${env}= is required"
        exit 1
    fi
}

## DRIVER
main() {
    for arg in "$@"; do
        export "$arg"
    done

    func="${func:-$default_func}"
    "$func"
}
