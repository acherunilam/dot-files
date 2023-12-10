# shellcheck shell=bash
# shellcheck disable=SC1091,SC2207,SC2155


include "/usr/share/bash-completion/bash_completion"


_git_ru() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local pos=${COMP_CWORD}
    local remotes="$(git remote show)"
    COMPREPLY=()
    [[ pos -eq 2 ]] && COMPREPLY=( $(compgen -W "$remotes" "$cur") )
}


_otp() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local pos=${COMP_CWORD}
    COMPREPLY=()
    [[ pos -eq 1 ]] && COMPREPLY=( $(compgen -W "${OTP_KEYS[*]}" "$cur") )
}
complete -F _otp otp


_pass() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local pos=${COMP_CWORD}
    COMPREPLY=()
    [[ pos -eq 1 ]] && COMPREPLY=( $(compgen -W "get set del help" "$cur") )
}
complete -F _pass pass


include "/usr/share/bash-completion/completions/systemctl"
complete -F _systemctl scl


_ts() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local pos=${COMP_CWORD}
    declare -A tailscale_nodes=$TAILSCALE_EXIT_NODES
    COMPREPLY=()
    [[ pos -eq 1 ]] && COMPREPLY=( $(compgen -W "${!tailscale_nodes[*]}" "$cur") )
}
complete -F _ts ts
