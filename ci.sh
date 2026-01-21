#!/bin/bash

# USAGE: example: Copy below comment to a file and run it.
# === my_ci.sh === #
# #!/bin/bash
#
# source ci.sh
#
# job=mjob1 needs=mjob2 \
# sched && {
#     echo Job 1
# }
#
# job=mjob2 \
# sched && {
#     echo Job 2
# }
#
# job=mjob3 needs=mjob2,mjob1 \
# sched && {
#     echo Job 3
# }
# ========== #

SCRIPT="$(realpath "$0")"

# schema: job|needs|status
db=""
sched() {
    ${ran_one:-false} && exit 0
    if [[ ${run_job} ]]; then
        set +e
        [[ $job == $run_job ]] && export ran_one=true && set -e
    else
        echo "${job:-} scheduled $(sed 's/,/ /g' <<< "$needs")" 1>&3
        echo -e "\033[34m${job:-} scheduled $(sed 's/,/ /g' <<< "$needs")\033[0m"
        export n=$'\n'
        return 1
    fi
}

if ${first_time:-true}; then
    export first_time=false
    db="$(first_time=false bash "$SCRIPT" 3>&1 1>&2)"

    run() { # Actually schedule
        while [[ $(awk '$2 == "scheduled"' <<< "$db") ]]; do
            while read job status needs; do
                can_run=true
                for dep in $needs; do
                    dep_status="$(awk '$1 == "'$dep'" { print $2 }' <<< "$db")"
                    if [ "$dep_status" != "passed" ]; then
                        can_run=false
                        break
                    fi
                done
                if $can_run; then
                    run_job="$job"
                    echo ">> $job"
                    db="$(sed "s/^$job [^ ]*/$job running/" <<< "$db")"
                    if first_time=false run_job=$job bash "$SCRIPT"; then
                        db="$(sed "s/^$job running/$job passed/" <<< "$db")"
                    else
                        db="$(sed "s/^$job running/$job failed/" <<< "$db")"
                        for dep in $(awk '{for(i=3;i<=NF;i++) if($i=="'$job'"){print $1;break}}' <<< "$db"); do
                            # echo "Skipping: $dep"
                            db="$(sed "s/$dep [^ ]*/$dep skipped/" <<< "$db")"
                        done
                    fi
                    break
                fi
            done < <(echo "$db" | grep scheduled)
        done
    }
    run
    echo ==========
    echo "$db" | awk '{ print $1FS$2 }' | column -t -o' | ' -N$(echo -e "\033[1mJOB,STATUS\033[0m")
    exit 0
fi
