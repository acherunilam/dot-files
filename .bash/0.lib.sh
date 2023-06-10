# shellcheck shell=bash
# shellcheck disable=SC1090


# Print the error message. Unless specified otherwise, it returns
# a code of 1.
#
# Usage:
#       error <message> [<return_code>] ; return
error() {
    local message="$1"
    local exit_code=${2:-1}
    local stdout_or_err
    [[ $exit_code -eq 0 ]] && stdout_or_err=1 || stdout_or_err=2
    echo -e "${FUNCNAME[-1]}: $message" >&$stdout_or_err
    return "$exit_code"
}


# Source a file only if it exists.
#
# Usage:
#       include <file_path>
include() {
    [[ -f "$1" ]] && source "$1"
}


# Check whether the environment variables exist.
#
# Usage:
#       validate-env <env>... || return
validate-env() {
    local exit_code=0
    for env_var in "$@" ; do
        if [[ -z "${!env_var}" ]] ; then
            echo "${FUNCNAME[1]}: please set the environment variable \$$env_var"
            exit_code=1
        fi
    done
    return "$exit_code"
}
