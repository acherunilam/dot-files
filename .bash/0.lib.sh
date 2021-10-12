# shellcheck shell=bash


# Prints the given error message. Unless specified otherwise, it returns a
# code of 1.
#
# Usage:
#       error <message> <return_code>
error() {
    [[ $2 -eq 0 ]] && stdout_or_err=1 || stdout_or_err=2
    echo -e "${FUNCNAME[1]}: $1" >&$stdout_or_err
    return "${2:-1}"
}