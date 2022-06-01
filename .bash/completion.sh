# shellcheck shell=bash
# shellcheck disable=SC1091,SC2207,SC2155


# Enable Bash completion.
include "/usr/share/bash-completion/bash_completion"


# Update Git repository's remote from HTTPS to SSH.
_git_ru() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local pos=${COMP_CWORD}
    local remotes="$(git remote show)"
    COMPREPLY=()
    [[ pos -eq 2 ]] && COMPREPLY=( $(compgen -W "$remotes" "$cur") )
}


# macOS-specific helper for generating TOTPs.
_otp() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local pos=${COMP_CWORD}
  COMPREPLY=()
  [[ pos -eq 1 ]] && COMPREPLY=( $(compgen -W "${OTP_KEYS[*]}" "$cur") )
}
complete -F _otp otp


# macOS Keychain-backed key-value CRUD helper.
_pass() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local pos=${COMP_CWORD}
  COMPREPLY=()
  [[ pos -eq 1 ]] && COMPREPLY=( $(compgen -W "get set del help" "$cur") )
}
complete -F _pass pass


# Systemd inspection.
include "/usr/share/bash-completion/completions/systemctl"
complete -F _systemctl scl