if [ "${DYN_SHE-}" != "yep" ]; then
    shell_exe=""
    if [ -r "/proc/$$/exe" ]; then
        shell_exe=$(readlink "/proc/$$/exe" 2>/dev/null || :)
    fi

    echo "Shell exe: $shell_exe"

    if [ "$shell_exe" = "/bin/sh" ]; then
        if [ -x /bin/bash ]; then
            DYN_SHE=yep exec /bin/bash "$0" "$@"
        elif [ -x /bin/busybox ]; then
            DYN_SHE=yep exec /bin/busybox sh "$0" "$@"
        fi
    fi
fi
