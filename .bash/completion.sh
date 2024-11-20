# shellcheck shell=bash
# shellcheck disable=SC1091,SC2207,SC2155

include "/usr/share/bash-completion/bash_completion"

_git_ru() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local pos=${COMP_CWORD}
	local remotes="$(git remote show)"
	COMPREPLY=()
	[[ pos -eq 2 ]] && COMPREPLY=($(compgen -W "$remotes" "$cur"))
}

_jcl() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local pos=${COMP_CWORD}
	local services="$(
		command systemctl list-units --legend false --no-pager --type service |
			command sed 's/^●//g' |
			command awk '{print $1}' |
			command sed 's/.service$//g' |
			command sort
	)"
	COMPREPLY=()
	[[ pos -eq 1 ]] && COMPREPLY=($(compgen -W "$services" "$cur"))
}
complete -F _jcl jcl

_otp() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local pos=${COMP_CWORD}
	COMPREPLY=()
	[[ pos -eq 1 ]] && COMPREPLY=($(compgen -W "${OTP_KEYS[*]}" "$cur"))
}
complete -F _otp otp

_pass() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local pos=${COMP_CWORD}
	COMPREPLY=()
	[[ pos -eq 1 ]] && COMPREPLY=($(compgen -W "get set del help" "$cur"))
}
complete -F _pass pass

include "/usr/share/bash-completion/completions/systemctl"
complete -F _systemctl scl

_ts() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local pos=${COMP_CWORD}
	COMPREPLY=()
	[[ pos -eq 1 ]] && COMPREPLY=($(compgen -W "${TAILSCALE_EXIT_NODES[*]}" "$cur"))
}
complete -F _ts ts
