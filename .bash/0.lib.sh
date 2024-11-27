# shellcheck shell=bash
# shellcheck disable=SC1090


# Safely enter a directory.
#
# Usage:
#       cd_dir <dir> || return
cd_dir() {
    local target_dir="$1"
    local exit_code=0
    if ! cd "$target_dir" 2>/dev/null ; then
        echo "${FUNCNAME[-1]}: unable to cd into '$target_dir'" >&2
        exit_code=1
    fi
    return "$exit_code"
}


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
