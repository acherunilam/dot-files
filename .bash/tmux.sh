# shellcheck shell=bash

[[ -z $TMUX ]] && return

# Pull SSH_AUTH_SOCK, DISPLAY, etc. from the tmux session, so that existing
# panes keep working after re-attaching over a new SSH connection.
#
# Usage:
#       tmux-refresh-env
tmux-refresh-env() {
	eval "$(command tmux show-environment -s 2>/dev/null)"
}
PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND%;};}tmux-refresh-env"
