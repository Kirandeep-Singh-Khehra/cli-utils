#!/bin/bash

n_jobs="${n_jobs:-1}"
pipe="sched"

init() {
    mkfifo "${1:-$pipe}"
}

_evalw() {
    cmd="$1"
    echo "[$1]"
}
export -f _evalw

listen() {
    exec 4<>"${1:-$pipe}"
    xargs -r -P "$n_jobs" -I% -0 bash -c '_evalw "$1"' _ "%" <&4
}

run() {
    printf "$1\0" > $pipe
}

main() {
    cmd="$1"
    shift

    case "$cmd" in
        init)
            init "$@"
            ;;
        listen)
            listen "$@"
            ;;
        run)
            run "$@"
            ;;
        *)
            echo "Err: no such cmd '$cmd'"
            ;;
    esac
}
main "$@"
